# load dependency packages
using GLFW, ModernGL, Quaternions
include(joinpath(dirname(@__FILE__), "glutils.jl"))


## data
imageDims = size(deformgrid)
meshgridFlag = true
glyphFlag = true
# draw deformable vector glyph
blankGlyph = [GLfloat[i,j] for i in 1:imageDims[1], j in 1:imageDims[2]]
deformedGlyph = blankGlyph + deformgrid
blankPoints = [blankGlyph...;]
deformedPoints = [deformedGlyph...;]
glyphPoints = [deformedPoints, blankPoints;]
stripLen = map(norm, deformgrid)
stripLen = stripLen/maximum(stripLen)
glyphColor = GLfloat[[stripLen stripLen;]...;]

# indices for EBO
glyphIndices = GLuint[]

deformLen = prod(imageDims)
for i in 0:deformLen-1
	push!(glyphIndices, i)
	push!(glyphIndices, i+deformLen)
	push!(glyphIndices, typemax(GLuint))
end

# draw meshgrid
gridDims = imageDims
meshgrid = [GLfloat[i,j] for i in 1:gridDims[1], j in 1:gridDims[2]]
gridPoints = [meshgrid...;]
gridIndices = GLuint[]
# hline(y→)
for i in 0:gridDims[1]:prod(gridDims)-gridDims[1]
	append!(gridIndices, collect(i:i+gridDims[1]-1))
	push!(gridIndices, typemax(GLuint))
end
# vline(x↑)
for i in 0:gridDims[1]-1
	append!(gridIndices, collect(i:gridDims[1]:i+prod(gridDims)-gridDims[1]))
	push!(gridIndices, typemax(GLuint))
end


## OpenGL Pipeline
# window init global variables
glfwWidth = 800
glfwHeight = 800
window = C_NULL
# OpenGL init
# set up OpenGL context version(Mac only)
@static if is_apple()
	const VERSION_MAJOR = 4
	const VERSION_MINOR = 1
end

@assert startgl()


## meshgrid
# create VBO and EBO
meshgridVBO = GLuint[0]
glGenBuffers(1, Ref(meshgridVBO))
glBindBuffer(GL_ARRAY_BUFFER, meshgridVBO[])
glBufferData(GL_ARRAY_BUFFER, sizeof(gridPoints), gridPoints, GL_STATIC_DRAW)

meshgridEBO = GLuint[0]
glGenBuffers(1, Ref(meshgridEBO))
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, meshgridEBO[])
glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(gridIndices), gridIndices, GL_STATIC_DRAW)
# create VAO
meshgridVAO = GLuint[0]
glGenVertexArrays(1, Ref(meshgridVAO))
glBindVertexArray(meshgridVAO[])
glBindBuffer(GL_ARRAY_BUFFER, meshgridVBO[])
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, meshgridEBO[])
glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, C_NULL)
glEnableVertexAttribArray(0)
# create program
meshgridProgram = createprogram("meshgrid.vert", "meshgrid.frag")
meshgridModelMatrixLocation = glGetUniformLocation(meshgridProgram, "model")
meshgridViewMatrixLocation = glGetUniformLocation(meshgridProgram, "view")
meshgridProjectionMatrixLocation = glGetUniformLocation(meshgridProgram, "proj")
# unbind VAO
glBindVertexArray(0)


## glyph
# create VBO and EBO
glyphVBO = GLuint[0]
glGenBuffers(1, Ref(glyphVBO))
glBindBuffer(GL_ARRAY_BUFFER, glyphVBO[])
glBufferData(GL_ARRAY_BUFFER, sizeof(glyphPoints)+sizeof(glyphColor), C_NULL, GL_STATIC_DRAW)
# copy point data
glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(glyphPoints), glyphPoints)
# copy color data
glBufferSubData(GL_ARRAY_BUFFER, sizeof(glyphPoints), sizeof(glyphColor), glyphColor)

glyphEBO = GLuint[0]
glGenBuffers(1, Ref(glyphEBO))
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, glyphEBO[])
glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(glyphIndices), glyphIndices, GL_STATIC_DRAW)
# create VAO
glyphVAO = GLuint[0]
glGenVertexArrays(1, Ref(glyphVAO))
glBindVertexArray(glyphVAO[])
glBindBuffer(GL_ARRAY_BUFFER, glyphVBO[])
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, glyphEBO[])
glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), Ptr{GLvoid}(0))
glVertexAttribPointer(1, 1, GL_FLOAT, GL_FALSE, sizeof(GLfloat), Ptr{GLvoid}(sizeof(glyphPoints)))
glEnableVertexAttribArray(0)
glEnableVertexAttribArray(1)
# create program
glyphProgram = createprogram("glyph.vert", "glyph.frag"; geomSource="glyph.geom")
glyphModelMatrixLocation = glGetUniformLocation(glyphProgram, "model")
glyphViewMatrixLocation = glGetUniformLocation(glyphProgram, "view")
glyphProjectionMatrixLocation = glGetUniformLocation(glyphProgram, "proj")
# unbind VAO
glBindVertexArray(0)


## camera
# default settings
cameraPosition = GLfloat[gridDims[1]/1.5, gridDims[2]/2.5, maximum(gridDims)]
cameraSpeed = minimum(gridDims)
cameraHeadingSpeed = 30.0
cameraHeading = 0.0
# perspective
near = 0.1               # clipping near plane
far = 1000.0             # clipping far plane
fov = deg2rad(67)
aspectRatio = glfwWidth / glfwHeight
# perspective matrix
projectionMatrix = zeros(4, 4)
range = tan(0.5*fov) * near
Sx = 2.0*near / (range *aspectRatio + range * aspectRatio)
Sy = near / range
Sz = -(far + near) / (far - near)
Pz = -(2.0*far*near) / (far - near)
projectionMatrix = GLfloat[ Sx   0.0  0.0  0.0;
							0.0   Sy  0.0  0.0;
							0.0  0.0   Sz   Pz;
							0.0  0.0 -1.0  0.0]
# view matrix
viewMatrix = zeros(GLfloat, 4, 4)

transMatrix = GLfloat[ 1.0 0.0 0.0 -cameraPosition[1];
					   0.0 1.0 0.0 -cameraPosition[2];
					   0.0 0.0 1.0 -cameraPosition[3];
					   0.0 0.0 0.0                1.0]

quat = qrotation([0.0, 1.0, 0.0], deg2rad(-cameraHeading))
quatMatrix = rotationmatrix(quat)
rotationMatrix = eye(GLfloat, 4, 4)
rotationMatrix[1:3, 1:3] = deepcopy(quatMatrix)
viewMatrix = rotationMatrix * transMatrix
# meshgrid
glUseProgram(meshgridProgram)
glUniformMatrix4fv(meshgridViewMatrixLocation, 1, GL_FALSE, viewMatrix)
glUniformMatrix4fv(meshgridProjectionMatrixLocation, 1, GL_FALSE, projectionMatrix)
# glyph
glUseProgram(glyphProgram)
glUniformMatrix4fv(glyphViewMatrixLocation, 1, GL_FALSE, viewMatrix)
glUniformMatrix4fv(glyphProjectionMatrixLocation, 1, GL_FALSE, projectionMatrix)

# model matrix
modelMatrix = GLfloat[ 1.0 0.0 0.0 0;
					   0.0 1.0 0.0 0;
					   0.0 0.0 1.0 0;
					   0.0 0.0 0.0 1.0]

# forward, right and up -- lookat()
fwd = GLfloat[0.0, 0.0, -1.0, 0.0]
rgt = GLfloat[1.0, 0.0, 0.0, 0.0]
up = GLfloat[0.0, 1.0, 0.0, 0.0]


## rotate -90 degree
quatRoll = qrotation([fwd[1], fwd[2], fwd[3]], deg2rad(-90))
quat = quatRoll * quat
quatMatrix = rotationmatrix(quat)
rotationMatrix = eye(GLfloat, 4, 4)
rotationMatrix[1:3, 1:3] = deepcopy(quatMatrix)
fwd = rotationMatrix * GLfloat[0.0, 0.0, -1.0, 0.0]
rgt = rotationMatrix * GLfloat[1.0, 0.0, 0.0, 0.0]
up = rotationMatrix * GLfloat[0.0, 1.0, 0.0, 0.0]
cameraPosition = cameraPosition + fwd[1:3]
cameraPosition = cameraPosition + up[1:3]
cameraPosition = cameraPosition + rgt[1:3]
transMatrix = GLfloat[ 1.0 0.0 0.0 cameraPosition[1];
					   0.0 1.0 0.0 cameraPosition[2];
					   0.0 0.0 1.0 cameraPosition[3];
					   0.0 0.0 0.0               1.0]

viewMatrix = inv(rotationMatrix) * inv(transMatrix)
# meshgrid
glUseProgram(meshgridProgram)
glUniformMatrix4fv(meshgridViewMatrixLocation, 1, GL_FALSE, viewMatrix)
# glyph
glUseProgram(glyphProgram)
glUniformMatrix4fv(glyphViewMatrixLocation, 1, GL_FALSE, viewMatrix)

## color
# meshgrid
meshgridColorLocation = glGetUniformLocation(meshgridProgram, "inputColour")
glUseProgram(meshgridProgram)
glUniform4f(meshgridColorLocation, 1.0, 1.0, 1.0, 0.5)


## settings
# enable depth test
# glEnable(GL_DEPTH_TEST)
# glDepthFunc(GL_ALWAYS)
# blending
glEnable(GL_BLEND)
glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
# enable cull face
# 	glEnable(GL_CULL_FACE)
# 	glCullFace(GL_BACK)
# 	glFrontFace(GL_CCW)
glClearColor(0.3, 0.3, 0.3, 1.0)
glViewport(0, 0, glfwWidth, glfwHeight)
# enable restart index
glEnable(GL_PRIMITIVE_RESTART)
glPrimitiveRestartIndex(typemax(GLuint))


## rendering loop
previousCameraTime = time()
while !GLFW.WindowShouldClose(window)
	# show FPS
	updatefps(window)
	currentCameraTime = time()
	elapsedCameraTime = currentCameraTime - previousCameraTime
	previousCameraTime = currentCameraTime
	# clear drawing surface
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
	## drawing
	# meshgrid
	if meshgridFlag == 1
		glBindVertexArray(meshgridVAO[])
		glUseProgram(meshgridProgram)
		glUniformMatrix4fv(meshgridModelMatrixLocation, 1, GL_FALSE, modelMatrix)
		glDrawElements(GL_LINE_STRIP, size(gridIndices)[1], GL_UNSIGNED_INT, C_NULL)
		glBindVertexArray(0)
	end

	# glyph
	if glyphFlag == 1
		glBindVertexArray(glyphVAO[])
		glUseProgram(glyphProgram)
		glUniformMatrix4fv(glyphModelMatrixLocation, 1, GL_FALSE, modelMatrix)
		glDrawElements(GL_LINE_STRIP, size(glyphIndices)[1], GL_UNSIGNED_INT, C_NULL)
		glBindVertexArray(0)
	end

	# check and call events
	GLFW.PollEvents()
	# camera key callbacks
	cameraMovedFlag = false
	move = GLfloat[0.0, 0.0, 0.0]
	cameraYaw = GLfloat(0.0)
	cameraPitch = GLfloat(0.0)
	cameraRoll = GLfloat(0.0)
	if GLFW.GetKey(window, GLFW.KEY_A)
		move[1] -= cameraSpeed * elapsedCameraTime
		cameraMovedFlag = true
	end
	if GLFW.GetKey(window, GLFW.KEY_D)
		move[1] += cameraSpeed * elapsedCameraTime
		cameraMovedFlag = true
	end
	if GLFW.GetKey(window, GLFW.KEY_Q)
		move[2] += cameraSpeed * elapsedCameraTime
		cameraMovedFlag = true
	end
	if GLFW.GetKey(window, GLFW.KEY_E)
		move[2] -= cameraSpeed * elapsedCameraTime
		cameraMovedFlag = true
	end
	if GLFW.GetKey(window, GLFW.KEY_W)
		move[3] -= cameraSpeed * elapsedCameraTime
		cameraMovedFlag = true
	end
	if GLFW.GetKey(window, GLFW.KEY_S)
		move[3] += cameraSpeed * elapsedCameraTime
		cameraMovedFlag = true
	end
	if GLFW.GetKey(window, GLFW.KEY_LEFT)
		cameraYaw += cameraHeadingSpeed * elapsedCameraTime
		cameraMovedFlag = true
		# use quaternion
		quatYaw = qrotation([up[1], up[2], up[3]], deg2rad(cameraYaw))
		quat = quatYaw * quat
		quatMatrix = rotationmatrix(quat)
		rotationMatrix = eye(GLfloat, 4, 4)
		rotationMatrix[1:3, 1:3] = deepcopy(quatMatrix)
		fwd = rotationMatrix * GLfloat[0.0, 0.0, -1.0, 0.0]
		rgt = rotationMatrix * GLfloat[1.0, 0.0, 0.0, 0.0]
		up = rotationMatrix * GLfloat[0.0, 1.0, 0.0, 0.0]
	end
	if GLFW.GetKey(window, GLFW.KEY_RIGHT)
		cameraYaw -= cameraHeadingSpeed * elapsedCameraTime
		cameraMovedFlag = true
		# use quaternion
		quatYaw = qrotation([up[1], up[2], up[3]], deg2rad(cameraYaw))
		quat = quatYaw * quat
		quatMatrix = rotationmatrix(quat)
		rotationMatrix = eye(GLfloat, 4, 4)
		rotationMatrix[1:3, 1:3] = deepcopy(quatMatrix)
		fwd = rotationMatrix * GLfloat[0.0, 0.0, -1.0, 0.0]
		rgt = rotationMatrix * GLfloat[1.0, 0.0, 0.0, 0.0]
		up = rotationMatrix * GLfloat[0.0, 1.0, 0.0, 0.0]
	end
	if GLFW.GetKey(window, GLFW.KEY_UP)
		cameraPitch += cameraHeadingSpeed * elapsedCameraTime
		cameraMovedFlag = true
		# use quaternion
		quatPitch = qrotation([rgt[1], rgt[2], rgt[3]], deg2rad(cameraPitch))
		quat = quatPitch * quat
		quatMatrix = rotationmatrix(quat)
		rotationMatrix = eye(GLfloat, 4, 4)
		rotationMatrix[1:3, 1:3] = deepcopy(quatMatrix)
		fwd = rotationMatrix * GLfloat[0.0, 0.0, -1.0, 0.0]
		rgt = rotationMatrix * GLfloat[1.0, 0.0, 0.0, 0.0]
		up = rotationMatrix * GLfloat[0.0, 1.0, 0.0, 0.0]
	end
	if GLFW.GetKey(window, GLFW.KEY_DOWN)
		cameraPitch -= cameraHeadingSpeed * elapsedCameraTime
		cameraMovedFlag = true
		# use quaternion
		quatPitch = qrotation([rgt[1], rgt[2], rgt[3]], deg2rad(cameraPitch))
		quat = quatPitch * quat
		quatMatrix = rotationmatrix(quat)
		rotationMatrix = eye(GLfloat, 4, 4)
		rotationMatrix[1:3, 1:3] = deepcopy(quatMatrix)
		fwd = rotationMatrix * GLfloat[0.0, 0.0, -1.0, 0.0]
		rgt = rotationMatrix * GLfloat[1.0, 0.0, 0.0, 0.0]
		up = rotationMatrix * GLfloat[0.0, 1.0, 0.0, 0.0]
	end
	if GLFW.GetKey(window, GLFW.KEY_Z)
		cameraRoll -= cameraHeadingSpeed * elapsedCameraTime
		cameraMovedFlag = true
		# use quaternion
		quatRoll = qrotation([fwd[1], fwd[2], fwd[3]], deg2rad(cameraRoll))
		quat = quatRoll * quat
		quatMatrix = rotationmatrix(quat)
		rotationMatrix = eye(GLfloat, 4, 4)
		rotationMatrix[1:3, 1:3] = deepcopy(quatMatrix)
		fwd = rotationMatrix * GLfloat[0.0, 0.0, -1.0, 0.0]
		rgt = rotationMatrix * GLfloat[1.0, 0.0, 0.0, 0.0]
		up = rotationMatrix * GLfloat[0.0, 1.0, 0.0, 0.0]
	end
	if GLFW.GetKey(window, GLFW.KEY_C)
		cameraRoll += cameraHeadingSpeed * elapsedCameraTime
		cameraMovedFlag = true
		# use quaternion
		quatRoll = qrotation([fwd[1], fwd[2], fwd[3]], deg2rad(cameraRoll))
		quat = quatRoll * quat
		quatMatrix = rotationmatrix(quat)
		rotationMatrix = eye(GLfloat, 4, 4)
		rotationMatrix[1:3, 1:3] = deepcopy(quatMatrix)
		fwd = rotationMatrix * GLfloat[0.0, 0.0, -1.0, 0.0]
		rgt = rotationMatrix * GLfloat[1.0, 0.0, 0.0, 0.0]
		up = rotationMatrix * GLfloat[0.0, 1.0, 0.0, 0.0]
	end

	if cameraMovedFlag
		cameraPosition = cameraPosition + fwd[1:3] * -move[3]
		cameraPosition = cameraPosition + up[1:3] * move[2]
		cameraPosition = cameraPosition + rgt[1:3] * move[1]
		transMatrix = GLfloat[ 1.0 0.0 0.0 cameraPosition[1];
							   0.0 1.0 0.0 cameraPosition[2];
							   0.0 0.0 1.0 cameraPosition[3];
							   0.0 0.0 0.0               1.0]

		viewMatrix = inv(rotationMatrix) * inv(transMatrix)
		# meshgrid
		glUseProgram(meshgridProgram)
		glUniformMatrix4fv(meshgridViewMatrixLocation, 1, GL_FALSE, viewMatrix)
		# glyph
		glUseProgram(glyphProgram)
		glUniformMatrix4fv(glyphViewMatrixLocation, 1, GL_FALSE, viewMatrix)
	end
	# swap the buffers
	GLFW.SwapBuffers(window)
end


GLFW.Terminate()

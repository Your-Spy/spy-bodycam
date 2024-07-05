export class GameView {
    constructor() {
        this.vertexShaderSrc = `
            attribute vec2 a_position;
            attribute vec2 a_texcoord;
            uniform mat3 u_matrix;
            varying vec2 textureCoordinate;
            void main() {
                gl_Position = vec4(a_position, 0.0, 1.0);
                textureCoordinate = a_texcoord;
            }
        `;

        this.fragmentShaderSrc = `
            varying highp vec2 textureCoordinate;
            uniform sampler2D external_texture;
            void main()
            {
            gl_FragColor = texture2D(external_texture, textureCoordinate);
            }
        `;

        this.interval = null;
    }

    makeShader = (gl, type, src) => {
        const shader = gl.createShader(type);
        gl.shaderSource(shader, src);
        gl.compileShader(shader);
        return shader;
    }
    
    createTexture(gl) {
        const tex = gl.createTexture();
      
        const texPixels = new Uint8Array([0, 0, 255, 255]);
      
        gl.bindTexture(gl.TEXTURE_2D, tex);
        gl.texImage2D(
            gl.TEXTURE_2D,
            0,
            gl.RGBA,
            1,
            1,
            0,
            gl.RGBA,
            gl.UNSIGNED_BYTE,
            texPixels,
        );
      
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      
        // Magic hook sequence
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT);
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
      
        // Reset
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
      
        return tex;
    }
      
    createBuffers = (gl) => {
        const vertexBuff = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuff);
        gl.bufferData(
            gl.ARRAY_BUFFER,
            new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]),
            gl.STATIC_DRAW,
        );
      
        const texBuff = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, texBuff);
        gl.bufferData(
            gl.ARRAY_BUFFER,
            new Float32Array([0, 0, 1, 0, 0, 1, 1, 1]),
            gl.STATIC_DRAW,
        );
      
        return { vertexBuff, texBuff };
    }
    
    createProgram = (gl) => {
        const vertexShader = this.makeShader(gl, gl.VERTEX_SHADER, this.vertexShaderSrc);
        const fragmentShader = this.makeShader(gl, gl.FRAGMENT_SHADER, this.fragmentShaderSrc);
      
        const program = gl.createProgram();
      
        gl.attachShader(program, vertexShader);
        gl.attachShader(program, fragmentShader);
        gl.linkProgram(program);
        gl.useProgram(program);
      
        const vloc = gl.getAttribLocation(program, 'a_position');
        const tloc = gl.getAttribLocation(program, 'a_texcoord');
      
        return { program, vloc, tloc };
    }
      
    createStuff(gl) {
        const tex = this.createTexture(gl);
        const { program, vloc, tloc } = this.createProgram(gl);
        const { vertexBuff, texBuff } = this.createBuffers(gl);
    
        gl.useProgram(program);
    
        gl.bindTexture(gl.TEXTURE_2D, tex);
    
        gl.uniform1i(gl.getUniformLocation(program, 'external_texture'), 0);
    
        gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuff);
        gl.vertexAttribPointer(vloc, 2, gl.FLOAT, false, 0, 0);
        gl.enableVertexAttribArray(vloc);
    
        gl.bindBuffer(gl.ARRAY_BUFFER, texBuff);
        gl.vertexAttribPointer(tloc, 2, gl.FLOAT, false, 0, 0);
        gl.enableVertexAttribArray(tloc);
    
        gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
    }

    render(gl, gameView) {
        gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
        gl.finish();
    
        let render = () => {};
        gameView.animationFrame = requestAnimationFrame(render);
    }
    
    createGameView = (canvas) => {
        this.canvas = canvas;
        const gl = this.canvas.getContext('webgl', {
            antialias: false,
            depth: false,
            stencil: false,
            alpha: false,
            desynchronized: true,
            failIfMajorPerformanceCaveat: false,
        });
      
        const gameView = {
            canvas,
            gl,
            animationFrame: undefined,
            resize: (width, height) => {
                gl.viewport(0, 0, width, height);
                gl.canvas.width = width;
                gl.canvas.height = height;
            },
        };
      
        this.createStuff(gl);

        this.interval = setInterval(() => {
            this.render(gl, gameView);
        }, 0);
      
        return gameView;
    }

    stop() {
        if (this.canvas) {
            if (this.canvas.style.display != "none") {
                this.canvas.style.display = "none";
            }

            if (this.interval) {
                clearInterval(this.interval);
            }
        }
    }
}
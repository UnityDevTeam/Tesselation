
Shader "Hidden/VD-AMBIENTOCCLUSION" {

	SubShader {
		
		Pass {
		
			cull off 
			fog {mode off}
			Lighting Off
			Color [_VDOccluderColor]

		}	
				
	}
	
}

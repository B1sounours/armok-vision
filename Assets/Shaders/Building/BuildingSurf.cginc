#ifdef _BOUNDING_BOX_ENABLED
	clip(IN.worldPos - _ViewMin);
	clip(_ViewMax - IN.worldPos);
#endif

float4 texcoords = TexCoords(IN);
//get the mask 
fixed4 dfTex = UNITY_SAMPLE_TEX2DARRAY(_MatTexArray, float3(texcoords.zw, UNITY_ACCESS_INSTANCED_PROP(_MatIndex_arr, _MatIndex)));
fixed4 matColor = UNITY_ACCESS_INSTANCED_PROP(_MatColor_arr, _MatColor);
fixed3 albedo = matColor.rgb;
fixed4 shape = UNITY_SAMPLE_TEX2DARRAY(_ShapeMap, float3(texcoords.zw, UNITY_ACCESS_INSTANCED_PROP(_ShapeIndex_arr, _ShapeIndex)));

fixed3 normal = UnpackNormal(shape.ggga);

#ifdef _PATTERN_MASK
fixed4 pattern_mask = tex2D(_PatternMask, texcoords.zw);
albedo = lerp(albedo, _Color1.rgb, pattern_mask.r);
albedo = lerp(albedo, _Color2.rgb, pattern_mask.g);
albedo = lerp(albedo, _Color3.rgb, pattern_mask.b);
#endif

albedo = dfTex.rgb * albedo;
half smoothness = dfTex.a;
half metallic = max((matColor.a * 2) - 1, 0);
fixed alpha = min(matColor.a * 2, 1);

fixed4 c = tex2D(_MainTex, texcoords.xy) * _Color;

#ifdef _NORMALMAP
    fixed3 customNormal = UnpackScaleNormal(tex2D(_BumpMap, texcoords.xy), _BumpScale);
#endif
#ifdef _TEXTURE_MASK
	fixed4 mask = tex2D(_DFMask, texcoords.xy);
#ifdef _NORMALMAP
    normal = lerp(BlendNormals(normal, customNormal), customNormal, mask.r);
#endif
    albedo = lerp(albedo, c.rgb, mask.r);
	albedo = lerp(albedo, c.rgb * dfTex.rgb * matColor.rgb, max(mask.g - mask.r, 0));
	albedo = lerp(albedo, UNITY_ACCESS_INSTANCED_PROP(_JobColor_arr, _JobColor), 1 - mask.a);
	alpha = lerp(c.a * alpha, c.a, mask.r);
	#ifdef _METALLICGLOSSMAP
        fixed4 m = tex2D(_MetallicGlossMap, texcoords.xy);
        metallic = lerp(metallic, m.r, mask.r);
		smoothness = lerp(smoothness, m.a * _GlossMapScale, mask.b);
	#else
		metallic = lerp(metallic, _Metallic, mask.r);
		smoothness = lerp(smoothness, _Glossiness, mask.b);
	#endif
#else
    alpha = c.a * alpha;
    #ifdef _NORMALMAP
        normal = BlendNormals(normal, customNormal);
    #endif
#endif


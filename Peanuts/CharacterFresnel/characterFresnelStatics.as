
UFUNCTION()
void EnableCharacterFresnel(UMaterialParameterCollection CharacterMaterialParameters, float BlendDuration = 1.0f)
{
	Material::SetScalarParameterValue(CharacterMaterialParameters, n"CharacterFresnelBlendTarget", 1.0f);
	Material::SetScalarParameterValue(CharacterMaterialParameters, n"CharacterFresnelBlendStartTime", Time::GetGameTimeSeconds());
	Material::SetScalarParameterValue(CharacterMaterialParameters, n"CharacterFresnelBlendDuration", BlendDuration);
}

UFUNCTION()
void DisableCharacterFresnel(UMaterialParameterCollection CharacterMaterialParameters, float BlendDuration = 1.0f)
{
	Material::SetScalarParameterValue(CharacterMaterialParameters, n"CharacterFresnelBlendTarget", 0.0f);
	Material::SetScalarParameterValue(CharacterMaterialParameters, n"CharacterFresnelBlendStartTime", Time::GetGameTimeSeconds());
	Material::SetScalarParameterValue(CharacterMaterialParameters, n"CharacterFresnelBlendDuration", BlendDuration);
}

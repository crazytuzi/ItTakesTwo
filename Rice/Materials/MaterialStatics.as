namespace MaterialStatics
{
	void ReparentMeshMaterialsToCharacterMaterial(UMeshComponent& Mesh, const UMaterialInterface& NewParentMaterial)
	{
		for(int i = 0; i < Mesh.Materials.Num(); i++)
		{
			UMaterialInstance MaterialInstance = Cast<UMaterialInstance>(Mesh.Materials[i]);
			UMaterialInstanceDynamic NewMaterialInstance = Material::CreateDynamicMaterialInstance(Cast<UMaterialInstance>(NewParentMaterial));
			CopyMaterialParametersToCharacterMaterial(MaterialInstance, NewMaterialInstance);
			Mesh.SetMaterial(i, NewMaterialInstance);
		}
	}

	void CopyMaterialParametersToCharacterMaterial(const UMaterialInstance& MaterialFrom, UMaterialInstanceDynamic& MaterialTo)
	{
		// Copy scalar parameters
		for(FScalarParameterValue ScalarParameter : MaterialFrom.ScalarParameterValues)
			MaterialTo.SetScalarParameterValue(ScalarParameter.ParameterInfo.Name, ScalarParameter.ParameterValue);

		// Copy vector parameters
		for(FVectorParameterValue VectorParameter : MaterialFrom.VectorParameterValues)
		{
			MaterialTo.SetVectorParameterValue(VectorParameter.ParameterInfo.Name, VectorParameter.ParameterValue);
			if(VectorParameter.ParameterInfo.Name == n"AlbedoColor")
			{
				FLinearColor LinearColor = FLinearColor(
					FMath::Pow(VectorParameter.ParameterValue.R, 2.2f) / 2.0f,
					FMath::Pow(VectorParameter.ParameterValue.G, 2.2f) / 2.0f,
					FMath::Pow(VectorParameter.ParameterValue.B, 2.2f) / 2.0f,
					FMath::Pow(VectorParameter.ParameterValue.A, 2.2f) / 2.0f);
				MaterialTo.SetVectorParameterValue(n"BaseColor Tint", LinearColor);
			}
		}

		// Copy texture parameters
		for(int i = 0; i < MaterialFrom.TextureParameterValues.Num(); i++)
		{
			MaterialTo.SetTextureParameterValue(MaterialFrom.TextureParameterValues[i].ParameterInfo.Name, MaterialFrom.TextureParameterValues[i].ParameterValue);

			FString TextureParameterName = MaterialFrom.TextureParameterValues[i].ParameterInfo.Name.ToString();
			if(!TextureParameterName.Contains("C"))
			{
				FName AdjustedParameterName = FName("C" + TextureParameterName.Mid(1, TextureParameterName.Len()));
				MaterialTo.SetTextureParameterValue(AdjustedParameterName, MaterialFrom.TextureParameterValues[i].ParameterValue);
			}
		}
	}
}
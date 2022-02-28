struct FNotifierScalarParameter
{
	UPROPERTY()
	FName Name;

	UPROPERTY()
	float Value;
}
struct FNotifierVectorParameter
{
	UPROPERTY()
	FName Name;

	UPROPERTY()
	FLinearColor Value;
}
struct FNotifierTextureParameter
{
	UPROPERTY()
	FName Name;

	UPROPERTY()
	UTexture2D Value;
}

struct FNotifierScalarParameterCurve
{
	UPROPERTY()
	FName Name;

	UPROPERTY()
	FRuntimeFloatCurve Value;
}
struct FNotifierVectorParameterCurve
{
	UPROPERTY()
	FName Name;

	UPROPERTY()
	FRuntimeCurveLinearColor Value;
}

void MakeMaterialsDynamic(USkeletalMeshComponent MeshComp, int Index, bool AllMaterials)
{
	if(AllMaterials)
	{
		for(int i = 0; i < MeshComp.Materials.Num(); i++)
		{
			MeshComp.CreateDynamicMaterialInstance(i);
		}
	}
	else
	{
		MeshComp.CreateDynamicMaterialInstance(Index);
	}
}

TArray<int> GetMaterialIndicesToChange(USkeletalMeshComponent MeshComp, int Index, bool AllMaterials)
{
	TArray<int> Result;
	
	if(AllMaterials)
	{
		for(int i = 0; i < MeshComp.Materials.Num(); i++)
		{
			Result.Add(i);
		}
	}
	else
	{
		Result.Add(Index);
	}
	return Result;
}

// If this ends up not being nice, adding a TMap of UAnimNotifyStates and floats for current time in HazeSkeletalMeshComponent (ask jonas)
UCLASS(NotBlueprintable, meta = ("SetMaterialParameterCurve"))
class UAnimNotify_SetMaterialParameterCurve : UAnimNotifyState 
{
	// NOTE: This name must be unique per notifier and model.
	UPROPERTY()
	FName NotifierUniqueName;

	UPROPERTY()	
	bool AllMaterials;

	UPROPERTY()
	int MaterialIndex;

	UPROPERTY()
	TArray<FNotifierScalarParameterCurve> ScalarParameters;


	UMaterialInstanceDynamic GetFirstMat(USkeletalMeshComponent MeshComp) const
	{
		return Cast<UMaterialInstanceDynamic>(MeshComp.Materials[MaterialIndex]);
	}


	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration) const
	{
		MakeMaterialsDynamic(MeshComp, MaterialIndex, AllMaterials);
		auto MaterialsToChange = GetMaterialIndicesToChange(MeshComp, MaterialIndex, AllMaterials);

		auto FirstMat = GetFirstMat(MeshComp);
		FirstMat.SetScalarParameterValue(NotifierUniqueName, 0);

		return true;
	}


	UFUNCTION(BlueprintOverride)
	bool NotifyTick(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float FrameDeltaTime) const
	{
		auto MaterialsToChange = GetMaterialIndicesToChange(MeshComp, MaterialIndex, AllMaterials);

		auto FirstMat = GetFirstMat(MeshComp);
		float CurrentTime = FirstMat.GetScalarParameterValue(NotifierUniqueName) + FrameDeltaTime;
		FirstMat.SetScalarParameterValue(NotifierUniqueName, CurrentTime);

		float TotalDuration = Animation.GetAnimNotifyStateDuration(this);
		float NormalizedTime = FMath::Clamp(CurrentTime / TotalDuration, 0.0f, 1.0f);
		
		//Print("TotalDuration: " + TotalDuration);
		//Print("CurrentTime: " + CurrentTime);
		//Print("NormalizedTime: " + NormalizedTime);
		for(int i = 0; i < MaterialsToChange.Num(); i++)
		{
			UMaterialInstanceDynamic Mat = Cast<UMaterialInstanceDynamic>(MeshComp.Materials[MaterialsToChange[i]]);
			if(Mat == nullptr)
				continue;
			for(int j = 0; j < ScalarParameters.Num(); j++)
			{
				Mat.SetScalarParameterValue(ScalarParameters[j].Name, ScalarParameters[j].Value.GetFloatValue(NormalizedTime));
			}
		}
		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation)const
	{
		auto MaterialsToChange = GetMaterialIndicesToChange(MeshComp, MaterialIndex, AllMaterials);
		auto FirstMat = GetFirstMat(MeshComp);
		FirstMat.SetScalarParameterValue(NotifierUniqueName, 1);

		for(int i = 0; i < MaterialsToChange.Num(); i++)
		{
			UMaterialInstanceDynamic Mat = Cast<UMaterialInstanceDynamic>(MeshComp.Materials[MaterialsToChange[i]]);
			if(Mat == nullptr)
				continue;
			for(int j = 0; j < ScalarParameters.Num(); j++)
			{
				Mat.SetScalarParameterValue(ScalarParameters[j].Name, ScalarParameters[j].Value.GetFloatValue(1.0f));
			}
		}

		return true;
	}

}
UCLASS(NotBlueprintable, meta = ("SetMaterialParameter"))
class UAnimNotify_SetMaterialParameter : UAnimNotify 
{
	UPROPERTY()
	bool AllMaterials;

	UPROPERTY()
	int MaterialIndex;

	UPROPERTY()
	TArray<FNotifierScalarParameter> ScalarParameters;

	UPROPERTY()
	TArray<FNotifierVectorParameter> VectorParameters;

	UPROPERTY()
	TArray<FNotifierTextureParameter> TextureParameters;

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		MakeMaterialsDynamic(MeshComp, MaterialIndex, AllMaterials);
		auto MaterialsToChange = GetMaterialIndicesToChange(MeshComp, MaterialIndex, AllMaterials);

		for(int i = 0; i < MaterialsToChange.Num(); i++)
		{
			UMaterialInstanceDynamic Mat = Cast<UMaterialInstanceDynamic>(MeshComp.Materials[MaterialsToChange[i]]);
			if(Mat == nullptr)
				continue;
			for(int j = 0; j < ScalarParameters.Num(); j++)
			{
				Mat.SetScalarParameterValue(ScalarParameters[j].Name, ScalarParameters[j].Value);
			}

			for(int j = 0; j < VectorParameters.Num(); j++)
			{
				Mat.SetVectorParameterValue(VectorParameters[j].Name, VectorParameters[j].Value);
			}

			for(int j = 0; j < TextureParameters.Num(); j++)
			{
				Mat.SetTextureParameterValue(TextureParameters[j].Name, TextureParameters[j].Value);
			}
		}
		return true;
	}
};
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingSettings;

enum EIceSkatingFovSource
{
	Speed,
	Boost,
	Gate
}

struct FIceSkatingFovValue
{
	float Value = 0.f;
	float Time = -1.f;
}

class UIceSkatingCameraComponent : UActorComponent
{
	UPROPERTY(Category = "Settings")
	UHazeCameraSpringArmSettingsDataAsset Settings;

	TArray<FIceSkatingFovValue> FovValues;
	/*

	void ApplyFov(EIceSkatingFovSource Source, float Value, float Time = 0.f)
	{
		int Index = int(Source);
		if (FovValues.Num() <= Index)
			FovValues.SetNum(Index + 1);

		FovValues[Index].Value = Value;
		FovValues[Index].Time = Time;
	}

	float GetTargetFov() const
	{
		FIceSkatingCameraSettings CamSettings;
		float Result = CamSettings.BaseFov;
		for(auto& Entry : FovValues)
		{
			if (Entry.Time < 0.f)
				continue;

			Result += Entry.Value;
		}

		return Result;
	}

	void UpdateFov(float DeltaTime)
	{
		for(auto& Entry : FovValues)
		{
			Entry.Time -= DeltaTime;
		}
	}

	bool HasAppliedFov() const
	{
		for(auto& Entry : FovValues)
		{
			if (Entry.Time >= 0.f)
				return true;
		}

		return false;
	}
	*/
}
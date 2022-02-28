
struct FLookatFocusPointData
{
	FLookatFocusPointData()
	{

	}

	UPROPERTY()
 	AActor Actor;
	UPROPERTY()
	USceneComponent Component;
	UPROPERTY()
	float Duration = 3.0f;
	UPROPERTY()
	float FOV = 60.f;
	UPROPERTY()
	float POIBlendTime = 1.f;
	UPROPERTY()
	bool ShowLetterbox = false;

	UPROPERTY()
	bool ClearOnInput = false;

	UPROPERTY()
	UHazeCameraSettingsDataAsset OverrideCameraSettings;

	void GetSettingsParams(FCapabilityActivationSyncParams& Params)
	{
		Params.AddObject(n"Actor", Actor);
		Params.AddValue(n"Duration", Duration);
		Params.AddValue(n"FOV", FOV);
		Params.AddValue(n"POIBlendTime", POIBlendTime);

		if (ClearOnInput)
		{
			Params.AddActionState(n"ClearOnInput");
		}
		
		if (ShowLetterbox)
		{
			Params.AddActionState(n"ShowLetterbox");
		}
		
		Params.AddObject(n"CameraDataSettings", OverrideCameraSettings);
	}

	void SetFromActivationParams(FCapabilityActivationParams Params)
	{
		Actor = Cast<AActor>(Params.GetObject(n"Actor"));
		Duration = Params.GetValue(n"Duration");
		FOV = Params.GetValue(n"FOV");
		POIBlendTime = Params.GetValue(n"POIBlendTime");
		ShowLetterbox = Params.GetActionState(n"ShowLetterbox");
		OverrideCameraSettings = Cast<UHazeCameraSettingsDataAsset>(Params.GetObject(n"CameraDataSettings"));
		ClearOnInput = Params.GetActionState(n"ClearOnInput");
	} 
}

class ULookatFocusPointComponent : UActorComponent
{
	FLookatFocusPointData Settings;
	AHazePlayerCharacter Player;
	TArray<FName> Blocklist;

	void ClearData()
	{
		Blocklist.Reset();
		Settings = FLookatFocusPointData();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	void LookatFocusPoint()
	{
		Player.SetCapabilityActionState(n"LookAtFocusPoint", EHazeActionState::Active);
	}
}
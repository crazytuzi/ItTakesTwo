import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomStatics;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomCable;

event void FLightRoomActivationPointActivated(bool bActivated);
event void FLightRoomActivationPointLightProgress(float Progress);

class ALightRoomActivationPoints : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartActivationPointAudioEvent;

	// UPROPERTY(Category = "Audio Events")
	// UAkAudioEvent FullyChargedAudioEvent;

	// UPROPERTY(Category = "Audio Events")
	// UAkAudioEvent InactiveAudioEvent;

	UPROPERTY()
	FLinearColor SolarPanelUnlit;

	UPROPERTY()
	FLinearColor SolarPanelLit;

	UPROPERTY()
	FLightRoomActivationPointActivated ActivationPointActivated;

	UPROPERTY()
	FLightRoomActivationPointLightProgress ActivationPointLightProgress;

	UPROPERTY()
	ALightRoomCable ConnectedLightRoomCable;

	TArray<AHazeActor> OverlappingSpotlights;

	UPROPERTY()
	float TimeBeforeProgressStartDuration = 0.15f;
	float TimeBeforeProgressStart = 0.f;
	bool bShouldTickTimeBeforeProgress = false;

	UPROPERTY()
	float TimeToProgressDuration = 1.f; 
	float TimeToProgress = 0.f;
	bool bShouldTickTimeToProgress = false;
	bool bShouldTickUp = false;

	UPROPERTY()
	float FullyChargedCooldownDuration = .25f;
	float FullyChargedCooldown = 0.f;
	bool bShouldTickChargedCooldown = false;

	UPROPERTY()
	float GoingBackSpeedMultiplier = .3f;

	bool bLightOnActor = false;
	bool bFullyCharged = false;
	bool bWasPreviouslyFullyCharged = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeAkComp.HazePostEvent(StartActivationPointAudioEvent);
		Mesh.SetColorParameterValueOnMaterialIndex(1, n"Emissive Tint", SolarPanelUnlit);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldTickTimeBeforeProgress)
		{
			TimeBeforeProgressStart += DeltaTime;
			if (TimeBeforeProgressStart >= TimeBeforeProgressStartDuration)
			{
				bShouldTickTimeBeforeProgress = false;
				bShouldTickTimeToProgress = true;
				bShouldTickUp = true;
			}
		}

		if (bShouldTickTimeToProgress)
		{
			if (bShouldTickUp)
			{
				TimeToProgress += DeltaTime;
				if (TimeToProgress >= TimeToProgressDuration)
				{
					bShouldTickTimeToProgress = false;
					TimeToProgress = TimeToProgressDuration;
					bFullyCharged = true;
					bWasPreviouslyFullyCharged = true;
					ActivationPointActivated.Broadcast(true);
				}
				UpdateProgressMesh(TimeToProgress);
			} else
			{
				TimeToProgress -= DeltaTime * GoingBackSpeedMultiplier;
				bFullyCharged = false;
				if (TimeToProgress <= 0.f)
				{
					if (bWasPreviouslyFullyCharged)
						ActivationPointActivated.Broadcast(false);
					
					bWasPreviouslyFullyCharged = false;
					bShouldTickTimeToProgress = false;
					TimeToProgress = 0.f;
				}
				UpdateProgressMesh(TimeToProgress);
			}
		}

		if (bShouldTickChargedCooldown)
		{
			FullyChargedCooldown += DeltaTime;
			if (FullyChargedCooldown >= FullyChargedCooldownDuration)
			{
				bShouldTickChargedCooldown = false;
				bShouldTickTimeToProgress = true;
				bShouldTickUp = false;
			}
		}
	}

	void OverlappedByLight(ELightRoomSpotlight SpotlightType, AHazeActor Spotlight)
	{
		OverlappingSpotlights.AddUnique(Spotlight);
		
		if (OverlappingSpotlights.Num() == 1)
			OverlapStarted();
	}

	void EndOverlapByLight(ELightRoomSpotlight SpotlightType, AHazeActor Spotlight)
	{
		OverlappingSpotlights.Remove(Spotlight);
		
		if (OverlappingSpotlights.Num() == 0)
			OverlapStopped();
	}

	void OverlapStarted()
	{
		TimeBeforeProgressStart = 0.f;
		bShouldTickTimeBeforeProgress = true;
	}

	void OverlapStopped()
	{
		bShouldTickTimeBeforeProgress = false;
		if (!bFullyCharged)
		{
			bShouldTickTimeToProgress = true;
			bShouldTickUp = false;
		} else 
		{
			FullyChargedCooldown = 0.f;
			bShouldTickChargedCooldown = true;
		}
	}

	void UpdateProgressMesh(float ProgressTime)
	{
		float Percent = ProgressTime / TimeToProgressDuration;
		ConnectedLightRoomCable.SetCableProgression(Percent);
		HazeAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Platform_LightRoomActivationPoint_Charge", Percent);
		Mesh.SetColorParameterValueOnMaterialIndex(1, n"Emissive Tint", FMath::Lerp(SolarPanelUnlit, SolarPanelLit, Percent));

		// if(Percent == 0.0f)
		// 	HazeAkComp.HazePostEvent(InactiveAudioEvent);
		// if(Percent == 1.0f)
		// 	HazeAkComp.HazePostEvent(FullyChargedAudioEvent);

	}
}
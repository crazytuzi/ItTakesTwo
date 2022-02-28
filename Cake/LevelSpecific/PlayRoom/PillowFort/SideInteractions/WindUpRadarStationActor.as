import Vino.Interactions.InteractionComponent;
import Vino.Interactions.AnimNotify_Interaction;

class AWindupRadarStationActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RadarMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlanetRoot;
	default PlanetRoot.RelativeLocation = FVector(6, -65, 255);

	UPROPERTY(DefaultComponent, Attach = PlanetRoot)
	UStaticMeshComponent PlanetMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SatelliteRoot;
	default SatelliteRoot.RelativeLocation = FVector(101, -65, 160);

	UPROPERTY(DefaultComponent, Attach = SatelliteRoot)
	UStaticMeshComponent SatelliteMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RadarDishRoot;
	default RadarDishRoot.RelativeLocation = FVector(260, -110, 310);

	UPROPERTY(DefaultComponent, Attach = RadarDishRoot)
	UStaticMeshComponent RadarDishMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;
	default InteractionComp.MovementSettings.InitializeSmoothTeleport();

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent InteractionMesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 8000.f;

	
	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartAudioEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopAudioEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UForceFeedbackEffect OnInteractedForceFeedback;

	UPROPERTY(Category = "Setup")
	UAnimSequence CodyAnim;
	UPROPERTY(Category = "Setup")
	UAnimSequence MayAnim;
	UPROPERTY(Category = "Setup")
	bool AnimationHasAlignInfo = false;
	

	UPROPERTY(Category = "Settings")
	float PlanetSpeed = 20;
	UPROPERTY(Category = "Settings")
	float SatelliteSpeed = 40;
	UPROPERTY(Category = "Settings")
	float RadarDishSpeed = 10;
	UPROPERTY(Category = "Settings")
	float HowFarToMoveButton = -5.0f;

	
	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	FLinearColor ButtonsEmissiveLitColor;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	FLinearColor ButtonsEmissiveUnlitColor;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	FLinearColor ButtonsBaseLitColor;
	
	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	FLinearColor ButtonsBaseUnlitColor;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	FLinearColor TopEmissiveLitColor;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	FLinearColor TopEmissiveUnlitColor;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	FLinearColor TopBaseLitColor;
	
	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	FLinearColor TopBaseUnlitColor;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	FLinearColor InteractionButtonLitColor;
	
	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	FLinearColor InteractionButtonUnlitColor;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	int TopMaterialIndex;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	int ButtonsMaterialIndex;

	FVector ButtonStartLocation;

	FHazeAnimNotifyDelegate AnimNotifyDelegate;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FHazeTimeLike ButtonTimeLike;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FHazeTimeLike LightFadeTimeLike;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FHazeTimeLike AccelerationTimeLike;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FHazeTimeLike DeaccelerationTimeLike;

	bool bActivated = false;
	bool bPressingButton = false;

	bool bAccelerating = false;

	float CurrentSpeedAlpha = 0.0f;

	float MaxDistance = 6500.0f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"OnInteracted");
		//RadarMesh.SetScalarParameterValueOnMaterials(n"Pulse", 0.0f);

		ButtonStartLocation = InteractionMesh.RelativeLocation;

		ButtonTimeLike.BindUpdate(this, n"UpdateButtonTimeLike");
		ButtonTimeLike.BindFinished(this, n"FinishedButtonTimeLike");

		LightFadeTimeLike.BindUpdate(this, n"UpdateLightsFadeTimeLike");

		AccelerationTimeLike.BindUpdate(this, n"UpdateAccelerationTimeLike");
		AccelerationTimeLike.BindFinished(this, n"FinishedAccelerationTimeLikee");
		DeaccelerationTimeLike.BindUpdate(this, n"UpdateDeaccelerationTimeLike");
		DeaccelerationTimeLike.BindFinished(this, n"FinishedDeaccelerationTimeLike");

		RadarMesh.SetColorParameterValueOnMaterialIndex(ButtonsMaterialIndex, n"BaseColor Tint", ButtonsBaseUnlitColor);	
		RadarMesh.SetColorParameterValueOnMaterialIndex(ButtonsMaterialIndex, n"Emissive Tint", ButtonsEmissiveUnlitColor);	
		RadarMesh.SetColorParameterValueOnMaterialIndex(TopMaterialIndex, n"BaseColor Tint", TopBaseUnlitColor);
		RadarMesh.SetColorParameterValueOnMaterialIndex(TopMaterialIndex, n"Emissive Tint", TopEmissiveUnlitColor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bActivated || bAccelerating)
		{
			RotateActors();

			if(HasControl() && bActivated)
			{
				if(Game::GetMay().GetDistanceTo(this) >= MaxDistance && Game::GetCody().GetDistanceTo(this) >= MaxDistance)
				{
					NetDeactivateStation();
				}
			}
			
		}
	}

	void RotateActors()
	{
		FRotator CurrentPlanetRotation = PlanetMesh.RelativeRotation;
		CurrentPlanetRotation = FRotator(CurrentPlanetRotation.Pitch, CurrentPlanetRotation.Yaw - (PlanetSpeed * CurrentSpeedAlpha) * ActorDeltaSeconds, CurrentPlanetRotation.Roll);
		PlanetMesh.SetRelativeRotation(CurrentPlanetRotation);

		FRotator CurrentSatelliteRotation = SatelliteMesh.RelativeRotation;
		CurrentSatelliteRotation = FRotator(CurrentSatelliteRotation.Pitch, CurrentSatelliteRotation.Yaw - (SatelliteSpeed * CurrentSpeedAlpha) * ActorDeltaSeconds, CurrentSatelliteRotation.Roll);
		SatelliteMesh.SetRelativeRotation(CurrentSatelliteRotation);

		FRotator CurrentRadarDishRotation = RadarDishMesh.RelativeRotation;
		CurrentRadarDishRotation = FRotator(CurrentRadarDishRotation.Pitch, CurrentRadarDishRotation.Yaw - (RadarDishSpeed * CurrentSpeedAlpha) * ActorDeltaSeconds, CurrentRadarDishRotation.Roll);
		RadarDishMesh.SetRelativeRotation(CurrentRadarDishRotation);
	}

	UFUNCTION()
	void OnInteracted(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		InteractionComp.Disable(n"InUse");

		UAnimSequence AnimationToPlay = Player.IsMay() ? MayAnim : CodyAnim;
		Player.PlayEventAnimation(Animation = AnimationToPlay);

		AnimNotifyDelegate.BindUFunction(this, n"OnAnimationNotify");
		Player.BindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), AnimNotifyDelegate);

		bPressingButton = true;
		ButtonTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void OnAnimationNotify(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMesh, UAnimNotify AnimNotify)
	{
		Actor.UnbindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), AnimNotifyDelegate);

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);

		if(OnInteractedForceFeedback != nullptr && Player != nullptr)
			Player.PlayForceFeedback(OnInteractedForceFeedback, false, false, n"RadarStationInteracted");

		if(bActivated)
		{
			DeactivateStation();
		}
		else
		{
			ActivateStation();
		}
	}

	UFUNCTION()
	void ActivateStation()
	{
		LightFadeTimeLike.PlayFromStart();
		AccelerationTimeLike.PlayFromStart();
		bActivated = true;
		HazeAkComp.HazePostEvent(StartAudioEvent);
	}

	UFUNCTION()
	void DeactivateStation()
	{
		LightFadeTimeLike.ReverseFromEnd();
		DeaccelerationTimeLike.PlayFromStart();
		bActivated = false;
		HazeAkComp.HazePostEvent(StopAudioEvent);
	}

	UFUNCTION(NetFunction)
	void NetDeactivateStation()
	{
		DeactivateStation();
	}

	UFUNCTION()
	void UpdateButtonTimeLike(float CurValue)
	{
		FVector NewLocation = ButtonStartLocation;
		NewLocation.Y = FMath::Lerp(ButtonStartLocation.Y, ButtonStartLocation.Y + HowFarToMoveButton, CurValue);
		InteractionMesh.SetRelativeLocation(NewLocation);


		FLinearColor InteractionButtonColor = FMath::Lerp(InteractionButtonLitColor, InteractionButtonUnlitColor, CurValue);
		InteractionMesh.SetColorParameterValueOnMaterialIndex(0, n"Emissive Tint", InteractionButtonColor);
	}
		
	UFUNCTION()
	void FinishedButtonTimeLike()
	{
		if(bPressingButton)
		{
			ButtonTimeLike.ReverseFromEnd();
			bPressingButton = false;
		}
		else
		{
			InteractionComp.Enable(n"InUse");
		}

	}
	
	UFUNCTION()
	void UpdateLightsFadeTimeLike(float CurValue)
	{
		FLinearColor ButtonsEmissiveColor = FMath::Lerp(ButtonsEmissiveUnlitColor, ButtonsEmissiveLitColor, CurValue);
		FLinearColor ButtonsBaseColor = FMath::Lerp(ButtonsBaseUnlitColor, ButtonsBaseLitColor, CurValue);

		FLinearColor TopEmissiveColor = FMath::Lerp(TopEmissiveUnlitColor, TopEmissiveLitColor, CurValue);
		FLinearColor TopBaseColor = FMath::Lerp(TopBaseUnlitColor, TopBaseLitColor, CurValue);
		
		RadarMesh.SetColorParameterValueOnMaterialIndex(ButtonsMaterialIndex, n"BaseColor Tint", ButtonsBaseColor);	
		RadarMesh.SetColorParameterValueOnMaterialIndex(ButtonsMaterialIndex, n"Emissive Tint", ButtonsEmissiveColor);	
		RadarMesh.SetColorParameterValueOnMaterialIndex(TopMaterialIndex, n"BaseColor Tint", TopBaseColor);
		RadarMesh.SetColorParameterValueOnMaterialIndex(TopMaterialIndex, n"Emissive Tint", TopEmissiveColor);
	}

	
	UFUNCTION()
	void UpdateAccelerationTimeLike(float CurValue)
	{
		bAccelerating = true;
		CurrentSpeedAlpha = FMath::Lerp(0.0f, 1.0f, CurValue);
	}
			
	UFUNCTION()
	void FinishedAccelerationTimeLikee()
	{
		bAccelerating = false;
	}

	UFUNCTION()
	void UpdateDeaccelerationTimeLike(float CurValue)
	{
		bAccelerating = true;
		CurrentSpeedAlpha = FMath::Lerp(1.0f, 0.0f, CurValue);
	}

	UFUNCTION()
	void FinishedDeaccelerationTimeLike()
	{
		bAccelerating = false;
	}
}
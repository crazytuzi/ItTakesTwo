import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.Tomato;
import Vino.Audio.Capabilities.AudioTags;
import Peanuts.Audio.AudioStatics;
import Peanuts.Foghorn.FoghornStatics;

class UTomatoAudioCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	ATomato Tomato;
	AHazePlayerCharacter PlayerController; 
	UHazeMovementComponent MoveComp;
	UHazeAkComponent TomatoAkComp;
	UTomatoSettings Settings;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnBecomingPlant;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnExitPlant;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent Dash;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent DashHit;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent RollingVegDeath;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{		
		TomatoAkComp = UHazeAkComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Tomato = Cast<ATomato>(Owner);
		PlayerController = Cast<AHazePlayerCharacter>(Tomato.OwnerPlayer);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Tomato.bTomatoInitialized)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		HazeAudio::SetPlayerPanning(TomatoAkComp, PlayerController);
		TomatoAkComp.HazePostEvent(OnBecomingPlant);
		PlayerController.BlockCapabilities(AudioTags::PlayerAudioVelocityData, this);
		SetCanPlayEfforts(PlayerController.PlayerHazeAkComp, false);

		Settings = Tomato.Settings;
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!Tomato.bTomatoInitialized)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		TomatoAkComp.HazePostEvent(OnExitPlant);
		PlayerController.UnblockCapabilities(AudioTags::PlayerAudioVelocityData, this);
		SetCanPlayEfforts(PlayerController.PlayerHazeAkComp, true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ConsumeAction(n"TomatoDash") == EActionStateStatus::Active)
		{
			TomatoAkComp.HazePostEvent(Dash);
		}

		if(ConsumeAction(n"TomatoDashHit") == EActionStateStatus::Active)
		{
			TomatoAkComp.HazePostEvent(DashHit);
		}

		if(ConsumeAction(n"TomatoDeath") == EActionStateStatus::Active)
		{
			TomatoAkComp.HazePostEvent(RollingVegDeath);
		}

		float TomatoVelocity = MoveComp.GetActualVelocity().Size();
		float TomatoVelocityNormalized = HazeAudio::NormalizeRTPC01(TomatoVelocity, 0.f, Settings.MaxSpeed);

		TomatoAkComp.SetRTPCValue("Rtpc_Gameplay_Ability_ControllablePlant_Tomato_Velocity", TomatoVelocityNormalized, 0.f);

		FVector VelocityPlaneForward = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		float SlopeTilt = Math::DotToDegrees(MoveComp.Velocity.GetSafeNormal().DotProduct(VelocityPlaneForward));
		SlopeTilt = SlopeTilt * FMath::Sign(MoveComp.Velocity.DotProduct(MoveComp.WorldUp));

		float NormalizedSlopeTilt = FMath::Lerp(-1.f, Math::GetPercentageBetween(0.f, 45.f, SlopeTilt), 1.f);	

		TomatoAkComp.SetRTPCValue(HazeAudio::RTPC::CharacterSlopeTilt, NormalizedSlopeTilt);	

		if(ConsumeAction(n"AudioEnteredGoo") == EActionStateStatus::Active)
			TomatoAkComp.SetRTPCValue("Rtpc_Gameplay_Ability_ControllablePlant_RollingVegetables_SurfaceType", 1.f);

		if(ConsumeAction(n"AudioExitedGoo") == EActionStateStatus::Active)
			TomatoAkComp.SetRTPCValue("Rtpc_Gameplay_Ability_ControllablePlant_RollingVegetables_SurfaceType", 0.f);
	}
}

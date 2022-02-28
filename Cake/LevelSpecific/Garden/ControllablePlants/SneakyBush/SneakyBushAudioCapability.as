import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Garden.ControllablePlants.SneakyBush.SneakyBush;
import Vino.Movement.Components.MovementComponent;

class USneakyBushAudioCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	ASneakyBush SneakyBush;
	UHazeMovementComponent MoveComp;
	UHazeAkComponent SneakyBushAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnBecomingPlant;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnMove;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnExitPlant;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SneakyBushAkComp = UHazeAkComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		SneakyBush = Cast<ASneakyBush>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ConsumeAction(n"AudioOnBecomeSneakyBush") == EActionStateStatus::Active)
		{
			SneakyBushAkComp.HazePostEvent(OnBecomingPlant);
			//PrintScaled("On Become Sneaky Bush", 2.f, FLinearColor::Green, 2.f);
		}

		if (ConsumeAction(n"AudioOnMoveSneakyBush") == EActionStateStatus::Active)
		{
			SneakyBushAkComp.HazePostEvent(OnMove);
			//PrintScaled("On Move Sneaky Bush", 2.f, FLinearColor::Green, 2.f);
		}

		if (ConsumeAction(n"AudioExitSneakyBush") == EActionStateStatus::Active)
		{
			SneakyBushAkComp.HazePostEvent(OnExitPlant);
			//PrintScaled("On Exit Sneaky Bush", 2.f, FLinearColor::Green, 2.f);
		}

		float SneakyBushVelocity = MoveComp.GetActualVelocity().Size();
		float SneakyBushVelocityNormalized = HazeAudio::NormalizeRTPC01(SneakyBushVelocity, 0.f, 1000.f);
		SneakyBushAkComp.SetRTPCValue("Rtpc_Gameplay_Ability_ControllablePlant_SneakyBush_Velocity", SneakyBushVelocityNormalized, 0.f);
		//Print("SneakyBushVelocity" + SneakyBushVelocityNormalized);

		float SneakyBushAngularVelocity = MoveComp.GetRotationDelta();
		float SneakyBushAngularVelocityNormalized = HazeAudio::NormalizeRTPC01(SneakyBushAngularVelocity, 0.f, 0.2f);
		SneakyBushAkComp.SetRTPCValue("Rtpc_Gameplay_Ability_ControllablePlant_SneakyBush_AngularVelocity", SneakyBushAngularVelocityNormalized, 0.f);
		//Print("SneakyBushRotationDelta" + SneakyBushAngularVelocityNormalized);

	}

}
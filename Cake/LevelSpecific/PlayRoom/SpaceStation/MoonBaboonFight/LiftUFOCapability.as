import Peanuts.ButtonMash.Default.ButtonMashDefault;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonBoss;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeaturePlayRoomHoldingUFO;

class ULiftUfoCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	AMoonBaboonBoss Ufo;

	UPROPERTY()
	ULocomotionFeaturePlayRoomHoldingUFO Feature;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CamSettings;


	UButtonMashDefaultHandle MashHandle;
	float LiftValue = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"LiftUFO"))
        	return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"LiftUFO"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Ufo = Cast<AMoonBaboonBoss>(GetAttributeObject(n"UFO"));

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.ApplyCameraSettings(CamSettings, FHazeCameraBlendSettings(2.f), this);

		Player.AddLocomotionFeature(Feature);

		System::SetTimer(this, n"StartButtonMash", 1.4f, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		StopButtonMash(MashHandle);

		Player.ClearCameraSettingsByInstigator(this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

		Player.RemoveLocomotionFeature(Feature);
	}

	UFUNCTION()
	void StartButtonMash()
	{
		MashHandle = StartButtonMashDefaultAttachToComponent(Player, Ufo.UFOSkelMesh, n"Base", FVector(330.f, 0.f, 200.f));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (HasControl())
		{
			if (MashHandle != nullptr)
			{
				LiftValue -= 0.6f * DeltaTime;
				LiftValue += MashHandle.MashRateControlSide * 0.2f * DeltaTime;
				LiftValue = FMath::Clamp(LiftValue, 0.f, 1.f);
				Ufo.LiftSyncComp.SetValue(LiftValue);

				float ForceFeedback = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(0.f, 0.15f), LiftValue);
				Player.SetFrameForceFeedback(ForceFeedback, ForceFeedback);
				
				{
					if (LiftValue >= 0.7f)
						Ufo.EnableLaserGunInteraction();
					else
						Ufo.DisableLaserGunInteraction();
				}
			}
		}

		Player.SetAnimFloatParam(n"ButtonMashAmount", Ufo.LiftSyncComp.Value);
		Ufo.UFOSkelMesh.SetAnimFloatParam(n"LiftingUFO", Ufo.LiftSyncComp.Value);

		FHazeRequestLocomotionData Data;
		Data.AnimationTag = n"HoldingUFO";
		Player.RequestLocomotion(Data);
	}
}
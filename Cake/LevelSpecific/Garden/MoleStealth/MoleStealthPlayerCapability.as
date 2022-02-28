import Cake.LevelSpecific.Garden.MoleStealth.MoleStealthStatics;
import Vino.Movement.Dash.CharacterDashSettings;

class UMoleStealthPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MoleStealth");
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	UPROPERTY(Category = "Stealth")
	UHazeLocomotionStateMachineAsset CodySneakAsset;

	UPROPERTY(Category = "Stealth")
	UHazeLocomotionStateMachineAsset CodySneakNoiseShapesAsset;

	UPROPERTY(Category = "Stealth")
	UHazeLocomotionStateMachineAsset MaySneakAsset;

	UPROPERTY(Category = "Stealth")
	UHazeLocomotionStateMachineAsset MaySneakNoiseShapesAsset;

	UPROPERTY(Category = "Camera")
	UHazeCameraSettingsDataAsset CameraSettings;

	AHazePlayerCharacter Player;
	UHazeMovementComponent PlayerMoveComp;

	UMovementSettings MovementSettings;
	UCharacterAirDashSettings DashSettings;


	bool bIsUsingShapeAsset = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerMoveComp = UHazeMovementComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(n"MoleStealthActive"))
     		return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(n"MoleStealthActive"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UMovementSettings::SetMoveSpeed(Player, 450, this, EHazeSettingsPriority::Defaults);
		UMovementSettings::SetHorizontalAirSpeed(Player, 685, this, EHazeSettingsPriority::Defaults);
		UCharacterAirDashSettings::SetStartSpeed(Player, 1750, this, EHazeSettingsPriority::Defaults);
		UCharacterAirDashSettings::SetEndSpeed(Player, 700, this, EHazeSettingsPriority::Defaults);

		Player.ApplyCameraSettings(CameraSettings, 2.f, this);

		if(Player.IsCody())
		{
			Player.AddLocomotionAsset(CodySneakAsset, this, 200);
		}
		else
		{
			Player.AddLocomotionAsset(MaySneakAsset, this, 200);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UMovementSettings::ClearMoveSpeed(Player, this, EHazeSettingsPriority::Defaults);
		UMovementSettings::ClearHorizontalAirSpeed(Player, this, EHazeSettingsPriority::Defaults);
		UCharacterAirDashSettings::ClearStartSpeed(Player, this, EHazeSettingsPriority::Defaults);
		UCharacterAirDashSettings::ClearEndSpeed(Player, this, EHazeSettingsPriority::Defaults);

		Player.ClearCameraSettingsByInstigator(this);

		if(Player.IsCody())
		{
			Player.RemoveLocomotionAsset(CodySneakAsset, this);
			Player.RemoveLocomotionAsset(CodySneakNoiseShapesAsset, this);
		}
		else
		{
			Player.RemoveLocomotionAsset(MaySneakAsset, this);
			Player.RemoveLocomotionAsset(MaySneakNoiseShapesAsset, this);
		}
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(IsActioning(n"MoleStealthNoiseShapeActive") && !IsInsideBush())
		{
			if(!bIsUsingShapeAsset)
			{
				bIsUsingShapeAsset = true;
				if(Player.IsCody())
				{
					Player.RemoveLocomotionAsset(CodySneakAsset, this);
					Player.AddLocomotionAsset(CodySneakNoiseShapesAsset, this, 300);
				}
				else
				{
					Player.RemoveLocomotionAsset(MaySneakAsset, this);
					Player.AddLocomotionAsset(MaySneakNoiseShapesAsset, this, 300);
				}	
			}
		}
		else
		{
			if(bIsUsingShapeAsset)
			{
				bIsUsingShapeAsset = false;
				if(Player.IsCody())
				{
					Player.RemoveLocomotionAsset(CodySneakNoiseShapesAsset, this);
					Player.AddLocomotionAsset(CodySneakAsset, this, 200);
				}
				else
				{
					Player.RemoveLocomotionAsset(MaySneakNoiseShapesAsset, this);
					Player.AddLocomotionAsset(MaySneakAsset, this, 200);
				}			
			}
		}
		
		if(IsDebugActive())
		{
			auto StealthData = PlayerIsIncreasingMoleStealthSound(Player);
			if(StealthData.bHasIncreased == true)
			{
				if(UCharacterGroundPoundComponent::Get(Player).LandedThisFrame())
				{
					Print("GroundPounded", 3.f);
					Print("StealthData.bHasIncreased" + StealthData.IncreaseAmount, 3.f);
				}
				else if(PlayerMoveComp.BecameGrounded())
				{
					Print("Landed", 3.f);
					Print("StealthData.bHasIncreased" + StealthData.IncreaseAmount, 3.f);
				}

				else if(Player.IsAnyCapabilityActive(MovementSystemTags::Crouch))
				{
					Print("Crouching");
					Print("StealthData.bHasIncreased" + StealthData.IncreaseAmount);
				}
				else if(Player.IsAnyCapabilityActive(MovementSystemTags::Sprint))
				{
					Print("Sprinting", 3.f);
					Print("StealthData.bHasIncreased" + StealthData.IncreaseAmount);
				}
				else if(Player.IsAnyCapabilityActive(MovementSystemTags::Dash))
				{
					Print("Dashing", 3.f);
					Print("StealthData.bHasIncreased" + StealthData.IncreaseAmount);
				}
			}
		}
	}

	bool IsInsideBush() const
	{
		return IsActioning(n"IsInsideSneakyBush");
	}

	 /* Used by the Capability debug menu to show Custom debug info */
	UFUNCTION(BlueprintOverride)
	FString GetDebugString() const
	{
		FString Str = "";
		auto ManagerComponent = UMoleStealthPlayerComponent::Get(Game::GetCody());
		if(ManagerComponent != nullptr && ManagerComponent.CurrentManager != nullptr)
		{
			AMoleStealthManager CurrentManager = ManagerComponent.CurrentManager;

			if(CurrentManager.WaitingDetectionValidation)
			{
				Str += "\nWaitingDetectionValidation";
			}

			if(CurrentManager.bHasBeenDetected)
			{
				Str += "\nHasBeenDetected";
			}

			Str += "\nShouldBeDetected: " + CurrentManager.ShouldBeDetected() + "\n";

			if(ManagerComponent.bCodyIsABush)
			{
				Str += "\nCody is bush";
			}
			if(ManagerComponent.bMayIsInsideCodysBush)
			{
				Str += "\nMay is inside bush";
			}
			
			if(IsInsideBush())
			{
				Str += "\nI am inside bush";
			}

			Str += "\n";

			Str += "\nGetCodyDetectionSoundType: " + CurrentManager.GetCodyDetectionSoundType();
			Str += "\nCody IncreasingSound: " + CurrentManager.bIncreasingSound[EHazePlayer::Cody] + "\n";

			Str += "\nGetMayDetectionSoundType: " + CurrentManager.GetMayDetectionSoundType();
			Str += "\nMay IncreasingSound: " + CurrentManager.bIncreasingSound[EHazePlayer::May] + "\n";

			Str += "\nLastIncreaseAmount\n";
			Str += "" + CurrentManager.LastIncreaseAmount[0] + "\n" + CurrentManager.LastIncreaseAmount[1];
			Str += "\nTimeLeftToDecreaseSound: " + CurrentManager.DecreaseTimeCooldown();
			
		}

        return Str;
	}
}

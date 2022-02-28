import Cake.LevelSpecific.PlayRoom.GoldBerg.HeadButtingDino;
import Cake.LevelSpecific.PlayRoom.GoldBerg.HeadbuttingDinoAnimationDataComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.HeadButtableComponentTrigger;

class UHeadButtingDinoControllerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"RidingHeadbuttingDino");

	default CapabilityDebugCategory = n"DinoLand";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 120;

	AHeadButtingDino ControlledDino;
	AHazePlayerCharacter Player;

	UHeadbuttingDinoAnimationDataComponent AnimationData;

	bool bIsShowingSlamIcon;

	UPROPERTY()
    UAnimSequence MayRideDinoMH;

	UPROPERTY()
	UHazeCameraSettingsDataAsset CamSettings;

	UPROPERTY()
    UAnimSequence CodyRideDinoMH;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		AHeadButtingDino HeadbuttingDino = Cast<AHeadButtingDino>(GetAttributeObject(n"HeadbuttingDino"));

		if (HeadbuttingDino != nullptr)
		{
			return EHazeNetworkActivation::ActivateLocal;
		}
        else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(IsActioning(n"JumpOffHeadbuttingDino"))
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}

		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ControlledDino = Cast<AHeadButtingDino>(GetAttributeObject(n"HeadbuttingDino"));
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.SetActorEnableCollision(false);
		Player.SetActorTransform(ControlledDino.RidingPosition.GetWorldTransform());
		AnimationData =Cast<UHeadbuttingDinoAnimationDataComponent>(Player.GetOrCreateComponent(UHeadbuttingDinoAnimationDataComponent::StaticClass()));
		Player.TriggerMovementTransition(this);


		//FHazeCameraBlendSettings BlendSettings;
		//Player.ApplyCameraSettings(CamSettings, BlendSettings, this);
		//ControlledDino.Camera.ActivateCamera(Player, FHazeCameraBlendSettings(), this);
		SpawnIcons();
	}

	void SpawnIcons()
	{
		TArray<AActor> Volumes;
		Gameplay::GetAllActorsOfClass(AheadButtableComponentTrigger::StaticClass(), Volumes);

		for (auto Volume : Volumes)
		{
			AheadButtableComponentTrigger Trigger = Cast<AheadButtableComponentTrigger>(Volume);
			
			if (Player.IsCody())
			{
				Trigger.ActivationPoint.ChangeValidActivator(EHazeActivationPointActivatorType::Cody);
			}

			else
			{
				Trigger.ActivationPoint.ChangeValidActivator(EHazeActivationPointActivatorType::May);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ControlledDino.JumpOff();
		ControlledDino = nullptr;
		ConsumeAction(n"JumpOffHeadbuttingDino");
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.SetActorEnableCollision(true);
		Player.StopAllSlotAnimations();
		Player.ClearCameraSettingsByInstigator(this);
		Player.DeactivateCameraByInstigator(this);
		HideIcons();
	}

	void HideIcons()
	{
		TArray<AActor> Volumes;
		Gameplay::GetAllActorsOfClass(AheadButtableComponentTrigger::StaticClass(), Volumes);

		for (auto Volume : Volumes)
		{
			AheadButtableComponentTrigger Trigger = Cast<AheadButtableComponentTrigger>(Volume);
			Trigger.ActivationPoint.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ControlledDino.HasControl())
		{
			SendInput();
		}

		AnimationData.bEnteredDino = ControlledDino.bJumpedOn;
		AnimationData.bIsPlayingFailedHeadbutt = ControlledDino.ShouldPerformFailedHeadbutt;
		AnimationData.bIsHeadbutting = ControlledDino.IsHeadButting;
		AnimationData.bIsGrounded = ControlledDino.MoveComponent.IsGrounded();
		FHazeRequestLocomotionData LocomotionData;
		LocomotionData.AnimationTag = n"DinoSlammer";
		AnimationData.ForwardSpeedAlpha = ControlledDino.ForwardSpeedAlpha;

		if(Player.Mesh.CanRequestLocomotion())
		{
			Player.RequestLocomotion(LocomotionData);
		}

		Player.UpdateActivationPointAndWidgets(UHeadbuttingDinoActivationPoint::StaticClass());
	}

	UFUNCTION()
	void SendInput()
	{
		FVector MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		ControlledDino.SetMoveInput(MoveDirection);

		if (IsActioning(ActionNames::MovementJump))
		{
			ControlledDino.HeadButt();
		}
	}
}
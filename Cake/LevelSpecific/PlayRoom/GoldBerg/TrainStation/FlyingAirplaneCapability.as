import Cake.LevelSpecific.Music.LevelMechanics.Nightclub.MusicTunnel.MusicTunnelFeature;
import Vino.Camera.Capabilities.CameraVehicleChaseCapability;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.PlayRoom.GoldBerg.TrainStation.FlyingAirplane;
import Vino.Movement.MovementSystemTags;
import Vino.PlayerHealth.PlayerHealthStatics;

settings FlyingAirplaneCameraChaseSettings for UCameraVehicleChaseSettings
{
	// If player gives camera input, we pause chase for this long before resuming
	FlyingAirplaneCameraChaseSettings.CameraInputDelay = 0.4f; 				 

	// When chase has been active for a while, we'll accelerate behind the plane over this time. 
	// Reduce to keep up better, increase to get more sluggishness
	FlyingAirplaneCameraChaseSettings.AccelerationDuration = 1.f;

	// Acceleration when jumping on the plane. Increase to make transition smoother, reduce to for snappishness 
	FlyingAirplaneCameraChaseSettings.InitialAccelerationDuration = 2.f;

	// Acceleration after having given camera input. Increase to make transition smoother, reduce to for snappishness 
	FlyingAirplaneCameraChaseSettings.InputResetAccelerationDuration = 2.f;

	// When starting and giving input we take this long to resume normal acceleration
	FlyingAirplaneCameraChaseSettings.AccelerationChangeDuration = 2.f;

	// Camera will try to look at a position this far ahead of the airplane.
	// This means vehicle will be framed to the left when turning to the right and vice versa.
	FlyingAirplaneCameraChaseSettings.LookAheadDistance = 2000.f; 

	// This should always be false since we don't give any movement input
	FlyingAirplaneCameraChaseSettings.bOnlyChaseAfterMovementInput = false;
};

class UFlyingAirplaneCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 100;
	default CapabilityTags.Add(n"FlyingAirplane");

	UPROPERTY()
	UBlendSpace1D CodyHangBS;

	UPROPERTY()
	UBlendSpace1D MayHangBS;
	
	UPROPERTY()
	FHazeCameraBlendSettings BlendSettings;

	UPROPERTY()
	UAnimSequence CodyJump;

	UPROPERTY()
	UAnimSequence MayJump;

	UPROPERTY()
	FText RollText;

	AHazePlayerCharacter Player;
	AFlyingAirplane Airplane;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GetAttributeObject(n"Airplane") != nullptr)
		{
        	return EHazeNetworkActivation::ActivateUsingCrumb;
		}
		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}


	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		UObject AirplaneObject;
		ConsumeAttribute(n"Airplane", AirplaneObject);

		ActivationParams.AddObject(n"Airplane", AirplaneObject);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Airplane = Cast<AFlyingAirplane>(ActivationParams.GetObject(n"Airplane"));

		// Tweak camera chase settings to look slighly inwards
		UCameraVehicleChaseSettings ChaseSettings = FlyingAirplaneCameraChaseSettings;
		ChaseSettings.ChaseOffset.Yaw = (Airplane.bFlipDirection ? -15.f : 15.f);		
		Player.ApplySettings(FlyingAirplaneCameraChaseSettings, this, EHazeSettingsPriority::Gameplay);

		Airplane.CameraRoot.ActivateCamera(Player, BlendSettings, this, EHazeCameraPriority::High);

		Airplane.HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interaction_Airplanes_OnPlayerInteration", 1.f);

		if (Player.IsCody())
		{
			Player.PlayBlendSpace(CodyHangBS);
			Airplane.HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interaction_Airplanes_PlayerPanning", 1.f);
		}

		else
		{
			Player.PlayBlendSpace(MayHangBS);
			Airplane.HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interaction_Airplanes_PlayerPanning", -1.f);
		}

		Player.BlockCapabilities(n"Movement", this);
		Player.BlockCapabilities(n"Interaction", this);
		Player.AddCapability(UCameraVehicleChaseCapability::StaticClass());
		

		if (Player.IsCody())
		{
			Player.AttachToComponent(Airplane.InteractionCody, AttachmentRule = EAttachmentRule::SnapToTarget);
		}
		else
		{
			Player.AttachToComponent(Airplane.InteractionMay, AttachmentRule = EAttachmentRule::SnapToTarget);
		}

		FTutorialPrompt RollTutorialPrompt;
		RollTutorialPrompt.Action = ActionNames::MovementDash;
		RollTutorialPrompt.DisplayType = ETutorialPromptDisplay::Action;
		RollTutorialPrompt.MaximumDuration = 6;
		RollTutorialPrompt.Text = RollText;

		ShowTutorialPrompt(Player, RollTutorialPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeRequestLocomotionData LocoData;
		LocoData.AnimationTag = n"MusicTunnel";
		Player.RequestLocomotion(LocoData);

		if(WasActioning(ActionNames::MovementDash))
		{
			Airplane.PerformRoll();
			RemoveTutorialPromptByInstigator(Player, this);
		}

		if(WasActioning(ActionNames::MovementJump))
		{
			Player.SetAnimBoolParam(n"Jump", true);
		}

		// Offset camera pivot to show more of the inside flight path
		FHazeCameraSpringArmSettings TweakedSettings;
		FVector InsideDir = Airplane.ActorForwardVector.CrossProduct(FVector::UpVector);
		TweakedSettings.bUseWorldPivotOffset = true;

		if (Airplane.bFlipDirection)
		{
			TweakedSettings.WorldPivotOffset = InsideDir * 300.f;
		}	
		else 
		{
			TweakedSettings.WorldPivotOffset = InsideDir * -300.f;
		}

		Player.ApplyCameraSpringArmSettings(TweakedSettings, CameraBlend::Additive(1.f), this, EHazeCameraPriority::Script);

		FVector2D Direction = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		MovePlayer(Direction.X, DeltaTime);
	}

	UFUNCTION()
	void MovePlayer(float Direction, float DeltaTime)
	{
		// TODO, network support!!!
		float OffsetfromInteraction = Player.RootComponent.RelativeLocation.X;


		OffsetfromInteraction += DeltaTime * Direction * -250;

		if (Player.IsCody())
		{
			OffsetfromInteraction = FMath::Clamp(OffsetfromInteraction, -580, 70);
		}

		else
		{
			OffsetfromInteraction = FMath::Clamp(OffsetfromInteraction, -90, 610);
		}
		

		FVector RelativeLocation = Player.RootComponent.RelativeLocation;
		RelativeLocation.X = OffsetfromInteraction;

		FHitResult Result;
		Player.SetActorRelativeLocation(RelativeLocation, false, Result, false);
		Player.SetBlendSpaceValues(Direction);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Player.IsPlayerDead())
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		if (IsActioning(ActionNames::Cancel))
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
		if(IsActioning(ActionNames::MovementJump))
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Camera has BlendOutBehaviour 'FollowView' so it won't follow along with the plane when blending out
		Player.DeactivateCameraByInstigator(this);

		Airplane.EnableFlyingAirplaneInteraction(Player);
		Player.ClearSettingsByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);
		Player.StopBlendSpace();
		Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockCapabilities(n"Interaction", this);
		Player.RemoveCapability(UCameraVehicleChaseCapability::StaticClass());
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		RemoveTutorialPromptByInstigator(Player, this);
		//RemoveCancelPromptByInstigator(Player, this);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);

		Airplane.HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interaction_Airplanes_OnPlayerInteration", 0.f);
		Airplane.HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interaction_Airplanes_PlayerPanning", 0.f);
		Airplane.OnPlayerLeftAirplane();

		Player.MovementComponent.AddImpulse(Airplane.ActorForwardVector * -100);
		Player.MovementComponent.AddImpulse(FVector::UpVector * 2000);
		FHazePointOfInterest POI;
		POI.Duration = 2;
		POI.bMatchFocusDirection = true;
		POI.FocusTarget.Actor = Airplane;
		POI.Blend.BlendTime = 0.25;
		Player.ApplyPointOfInterest(POI, this);
	}
}

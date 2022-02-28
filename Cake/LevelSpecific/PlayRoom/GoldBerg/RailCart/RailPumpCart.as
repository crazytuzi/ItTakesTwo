import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailCart;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailCartRail;
import Vino.Interactions.InteractionComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Peanuts.Audio.AudioStatics;

import void StartUsingRailPumpCart(AHazePlayerCharacter Player, ARailPumpCart Cart, bool bFront, bool bTeleport) from "Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCartUserComponent";
import void StopUsingRailPumpCart(AHazePlayerCharacter Player) from "Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCartUserComponent";
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCartWidget;

// The pump-rail-cart that the players stand on and interact with!
class ARailPumpCart : ARailCart
{
	UPROPERTY(DefaultComponent, Attach = Mesh)
	UInteractionComponent BackInteraction;
	default BackInteraction.bUseLazyTriggerShapes = true;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UInteractionComponent FrontInteraction;
	default FrontInteraction.bUseLazyTriggerShapes = true;

	UPROPERTY(DefaultComponent)
	USceneComponent WidgetAttach;

	UPROPERTY(DefaultComponent)
	UHazeSplineFollowComponent SplineFollow;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 5000;
	default DisableComponent.bRenderWhileDisabled = true;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UCameraSpringArmComponent CameraSpringArm;

	UPROPERTY(DefaultComponent, Attach = CameraSpringArm)
	UHazeCameraComponent Camera;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionAssetBase MayLocomotion;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionAssetBase CodyLocomotion;

	UPROPERTY()
	UHazeCapabilitySheet UserSheet;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset BoostedCameraSettings;

	UPROPERTY(Category = "Camera")
	UCameraVehicleChaseSettings ChaseSettings;

	UPROPERTY(Category = "Widget")
	TSubclassOf<URailPumpCartWidget> WidgetClass;
	URailPumpCartWidget Widget;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BoostStartEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BoostStopEvent;

	UPROPERTY()
	ARailCartRail StartingRail;

	UPROPERTY()
	AHazePlayerCharacter FrontPlayer;

	UPROPERTY()
	AHazePlayerCharacter BackPlayer;

	float MaxSpeed = 5000.f;

	UPROPERTY()
	float BoostSpeed = 5000.f;

	float BoostFadeSpeed = 5000.f;
	float BoostFadeDuration = -1.f;

	float MaxMashRate = 7.f;

	float FrontPumpRate = 0.f;
	float BackPumpRate = 0.f;

	UPROPERTY()
	float Torque = 0.f;
	UPROPERTY()
	float WheelAngle = 0.f;

	bool bHasUpdatedBoost = false;

	UPROPERTY()
	float CombinedPumpRate = 0.f;

	UPROPERTY()
	bool bBoosting = false;

	// Locking (can't jump on it)
	bool bIsLocked = false;

	bool bInBoat = false;

	UPROPERTY(Category = "Animation")
	UAnimSequence MayEnterJumpAnimation;

	UPROPERTY(Category = "Animation")
	UAnimSequence CodyEnterJumpAnimation;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		BackInteraction.AttachTo(Mesh, n"BackSocket");
		FrontInteraction.AttachTo(Mesh, n"FrontSocket");
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Bind
		SplineFollow.OnSplineActivated.AddUFunction(this, n"HandleSplineActivated");
		SplineFollow.OnSplineDeactivated.AddUFunction(this, n"HandleSplineDeactivated");

		AddCapability(n"RailPumpCartMoveCapability");
		AddCapability(n"RailPumpCartDragCapability");
		AddCapability(n"RailPumpCartGravityCapability");
		AddCapability(n"RailPumpCartBoostCapability");
		AddCapability(n"RailPumpCartPumpCapability");
		AddCapability(n"RailPumpCartPumpWidgetCapability");
		AddCapability(n"RailPumpCartBoostFadeCapability");
		AddCapability(n"RailPumpCartAttachCapability");
		AddCapability(n"RailCartTiltCapability");
		AddCapability(n"RailCartOffsetCapability");
		AddCapability(n"RailCartTransferCapability");

		HazeAkComponent.bUseReverbVolumes = true;

		OnPreSequencerControl.AddUFunction(this, n"HandlePreSequenceControl");
		OnPostSequencerControl.AddUFunction(this, n"HandlePostSequenceControl");

		FrontInteraction.OnActivated.AddUFunction(this, n"HandleFrontInteraction");
		BackInteraction.OnActivated.AddUFunction(this, n"HandleBackInteraction");

		if (StartingRail != nullptr)
		{
			const bool bForwardOnSpline = true;
			SplineFollow.ActivateSplineMovement(StartingRail.Spline, bForwardOnSpline);
			SplineFollow.IncludeSplineInActorReplication(this);
		}
		else
		{
			devEnsure(false, "You have to set StartingRail on the RailCart, otherwise it won't be attached to anything");
		}

		BackInteraction.SetExclusiveForPlayer(EHazePlayer::May);
		FrontInteraction.SetExclusiveForPlayer(EHazePlayer::Cody);

		Capability::AddPlayerCapabilitySheetRequest(UserSheet, EHazeCapabilitySheetPriority::Normal, EHazeSelectPlayer::Both);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilitySheetRequest(UserSheet, EHazeCapabilitySheetPriority::Normal, EHazeSelectPlayer::Both);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		HazeAkComponent.SetRTPCValue("Rtpc_Vehicles_RailCart_WheelAngle_Torque", FMath::Max(Torque, WheelAngle), 0.f);
		// Print("WheelAngle_Torque"+ FMath::Max(Torque, WheelAngle), 0.f);
	}



	// Callback for the front interaction
	UFUNCTION()
	void HandleFrontInteraction(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		StartUsingRailPumpCart(Player, this, true, false);
	}

	// Callback for the back interaction
	UFUNCTION()
	void HandleBackInteraction(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		StartUsingRailPumpCart(Player, this, false, false);
	}

	UFUNCTION()
	void HandlePreSequenceControl(FHazePreSequencerControlParams Params)
	{
		BootPlayers();
		BlockCapabilities(RailCartTags::Cart, this);
		TriggerMovementTransition(this, n"Cutscene");
		Print("PreSequenceControl");
	}

	UFUNCTION()
	void HandlePostSequenceControl(FHazePostSequencerControlParams Params)
	{
		UnblockCapabilities(RailCartTags::Cart, this);
		TriggerMovementTransition(this, n"CutsceneStop");
	}

	// Sets that a player has started using this cart (either front or back player)
	void SetPlayerStartedUsingCart(bool bFront, AHazePlayerCharacter Player)
	{
		if (bFront)
		{
			FrontInteraction.Disable(n"Used");
			FrontPlayer = Player;
		}
		else
		{
			BackInteraction.Disable(n"Used");
			BackPlayer = Player;
		}
	}

	// Sets that a player has stopped using this cart (either front or back player)
	void SetPlayerStoppedUsingCart(bool bFront)
	{
		if (bFront)
		{
			FrontInteraction.Enable(n"Used");
			FrontPlayer = nullptr;
		}
		else
		{
			BackInteraction.Enable(n"Used");
			BackPlayer = nullptr;
		}
	}


	// This function is used firstly at the beggining of the game to set an initial rail
	// But also during gameplay to force-move the cart to a separate location
	UFUNCTION()
	void AttachToRail(ARailCartRail Rail, bool bNearWorldLocation = false, FVector WorldLocation = FVector::ZeroVector)
	{
		if (!HasControl())
			return;

		FHazeSplineSystemPosition SplinePosition;
		if(bNearWorldLocation)
		{
			SplinePosition = Rail.Spline.GetPositionClosestToWorldLocation(WorldLocation, true);
		}
		else
		{
			SplinePosition = Rail.Spline.GetPositionClosestToWorldLocation(GetActorLocation(), true);
		}

		NetAttachToRail(SplinePosition);
	}

	UFUNCTION(NetFunction)
	void NetAttachToRail(const FHazeSplineSystemPosition& SplinePosition)
	{
		Speed = 0.f;
		SplineFollow.ActivateSplineMovement(SplinePosition);
		SetActorTransform(SplinePosition.WorldTransform);
		Print("NetAttachToRail");
	}

	// Fades to boost-speed to some target value over some duration
	UFUNCTION()
	void FadeToTargetBoostSpeed(float TargetSpeed, float Duration)
	{
		BoostFadeSpeed = TargetSpeed;

		if (BoostFadeDuration < 0.f)
			BoostFadeDuration = Duration;
		else
			BoostFadeDuration += Duration;
	}

	// Returns if both players are on the cart
	bool AreBothPlayersOnCart()
	{
		return FrontPlayer != nullptr && BackPlayer != nullptr;
	}

	UFUNCTION()
	void HandleSplineActivated(FHazeSplineSystemPosition NewPosition)
	{
		Position = NewPosition;
		AttachToComponent(Position.Spline);
		SetActorRelativeTransform(Position.GetRelativeTransform());
	}

	UFUNCTION()
	void HandleSplineDeactivated(FHazeSplineSystemPosition OldPosition)
	{
		// ?????
	}			

	UFUNCTION(Category = "Vehicles|RailCart")
	void ForcePlayersIntoCart(AHazePlayerCharacter FrontPlayer, AHazePlayerCharacter BackPlayer)
	{
		StartUsingRailPumpCart(FrontPlayer, this, true, true);
		StartUsingRailPumpCart(BackPlayer, this, false, true);
	}

	UFUNCTION(Category = "Vehicles|RailCart")
	void BootPlayers()
	{
		if (FrontPlayer != nullptr)
			StopUsingRailPumpCart(FrontPlayer);
		if (BackPlayer != nullptr)
			StopUsingRailPumpCart(BackPlayer);
	}

	UFUNCTION(Category = "Vehicles|RailCart")
	void BootPlayersAndLockCart()
	{
		if (bIsLocked)
			return;

		bIsLocked = true;
		BootPlayers();

		if (!FrontInteraction.IsDisabled(n"Locked"))
		{
			FrontInteraction.Disable(n"Locked");
			BackInteraction.Disable(n"Locked");
		}
	}

	UFUNCTION(Category = "Vehicles|RailCart")
	void UnlockCart()
	{
		if (!bIsLocked)
			return;

		bIsLocked = false;

		if (FrontInteraction.IsDisabled(n"Locked"))
		{
			FrontInteraction.Enable(n"Locked");
			BackInteraction.Enable(n"Locked");
		}
	}

	UFUNCTION(Category = "Vehicles|RailCart")
	void EnableInteractionsForTrainStation()
	{
		// Special case, in train station we want to be able to jump on the cart
		// but not actually drive away
		if (FrontInteraction.IsDisabled(n"Locked"))
		{
			FrontInteraction.Enable(n"Locked");
			BackInteraction.Enable(n"Locked");
		}
	}

	// Handles the pumpcart in the boat. A lot needs to be disabled since the pumpcart is expensive to move
	UFUNCTION()
	void SetPumpcartInBoatVariables(AHazeActor Wheelboat, bool bStatus)
	{
		if(!bInBoat && bStatus)
		{
			bInBoat = true;
			OnPlacedInBoat();
			DisableActor(Wheelboat);		
		}
		else if(bInBoat && !bStatus)
		{
			bInBoat = true;
			OnLeftBoat();
			EnableActor(Wheelboat);	
		}
	}

	UFUNCTION(BlueprintEvent)
	protected void OnPlacedInBoat()
	{
		Log("Blueprint did not override this event.");
	}

	UFUNCTION(BlueprintEvent)
	protected void OnLeftBoat()
	{
		Log("Blueprint did not override this event.");
	}
}
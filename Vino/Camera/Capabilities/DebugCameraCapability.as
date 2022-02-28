import Vino.Movement.MovementSystemTags;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Control.DebugShortcutsEnableCapability;

class UDebugCameraCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	default CapabilityTags.Add(n"DebugCamera");
	default TickGroup = ECapabilityTickGroups::Input;
    default CapabilityDebugCategory = CapabilityTags::Debug;

	AHazePlayerCharacter PlayerOwner = nullptr;
	AHazeDebugCameraActor DebugCamera = nullptr;
	bool bLockedView = false;
	float BaseSpeed = 2000.f;
	float TapSpeedFactor = 1.f;
	FHazeAcceleratedFloat HoldSpeedFactor;
	float MaxHoldSpeedFactor = 5.f;
	float IncreaseSpeedTimeStarted = 0.f;
	float DecreaseSpeedTimeStarted = 0.f;
	float TapDuration = 0.25f;
	float LastTeleportTime = -BIG_NUMBER;

	FVector LastNetSyncedLocation = FVector::ZeroVector;
	FRotator LastNetSyncedRotation = FRotator::ZeroRotator;
	float NetSyncDelay = 0.f; 
	float NetSyncInterval = 0.1f;
	FHazeAcceleratedVector NetLagLocation;
	FHazeAcceleratedRotator NetLagRotation;
	FHitResult TeleportHit;
	float MoveUpAndDownDirection = 0;
	float WantedMoveDirection = 0;

	int SpeedDirection = 0;
	float SpeedDirectionMultiplier = 1.f;
	float MouseInputTime = 0.f;

	bool bIsDefault = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		UCameraUserComponent UserComp = UCameraUserComponent::Get(Owner);

		if(UserComp != nullptr)
		{
			if(UserComp.DebugCamera != nullptr)
			{
				DebugCamera = UserComp.DebugCamera;
			}
			else
			{
				DebugCamera = Cast<AHazeDebugCameraActor>(SpawnPersistentActor(AHazeDebugCameraActor::StaticClass(), Owner.ActorLocation, Owner.ActorRotation));
				UserComp.DebugCamera = DebugCamera;
			}	
		}
		// Note that there is no need to network the debug camera actor
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		DebugValues.UseExlusiveLockedCategory(FCameraTags::DebugCamera);

		// Activate
		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"ToggleDebugCamera", "ToggleDebugCamera");
			Handler.AddPassiveUserButton(EHazeDebugPassiveUserCategoryButtonType::DPadRight);
			Handler.AddPassiveUserButton(EHazeDebugPassiveUserCategoryButtonType::DebugCamera);
			if(bIsDefault)
				Handler.DisplayAsDefault();
		}

		// Deactivate
		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"DeactivateCamera", "ToggleDebugCamera");
			Handler.AddLockedCategoryButton(EHazeDebugLockedCategoryButtonType::DPadRight);
			Handler.AddLockedCategoryButton(EHazeDebugLockedCategoryButtonType::DebugCamera);
		}

		// Teleport	
		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"Teleport", "Teleport Player");
			Handler.AddLockedCategoryButton(EHazeDebugLockedCategoryButtonType::DPadLeft);
			Handler.AddLockedCategoryButton(EHazeDebugLockedCategoryButtonType::T);
		}

		// Lock view toggle
		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"LockView", "LockView");
			Handler.AddLockedCategoryButton(EHazeDebugLockedCategoryButtonType::StickRightPress);
			Handler.AddLockedCategoryButton(EHazeDebugLockedCategoryButtonType::Y);
		}


		// Increase speed
		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"IncreaseSpeed", "IncreaseSpeed");
			Handler.AddLockedCategoryButton(EHazeDebugLockedCategoryButtonType::ShoulderRight);
		}

		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"IncreaseSpeedHold", "IncreaseSpeed");	
			Handler.AddLockedCategoryButton(EHazeDebugLockedCategoryButtonType::ShoulderRight, EHazeDebugInputActivationType::Hold);
		}

		
		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"IncreaseSpeedHoldMouse", "IncreaseSpeed");	
			Handler.AddLockedCategoryButton(EHazeDebugLockedCategoryButtonType::MouseWheelAxis, EHazeDebugInputActivationType::PressOrHold);
		}

		// Decrease speed
		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"DecreaseSpeed", "DecreaseSpeed");	
			Handler.AddLockedCategoryButton(EHazeDebugLockedCategoryButtonType::ShoulderLeft);
		}

		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"DecreaseSpeedHold", "DecreaseSpeed");	
			Handler.AddLockedCategoryButton(EHazeDebugLockedCategoryButtonType::ShoulderLeft, EHazeDebugInputActivationType::Hold);
		}

		// Move Up
		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"Decend", "Decend");	
			Handler.AddLockedCategoryButton(EHazeDebugLockedCategoryButtonType::TriggerLeft, EHazeDebugInputActivationType::PressOrHold);
			Handler.AddLockedCategoryButton(EHazeDebugLockedCategoryButtonType::MouseButtonRight, EHazeDebugInputActivationType::PressOrHold);
		}

		// Move Down
		{
			FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"Accend", "Accend");
			Handler.AddLockedCategoryButton(EHazeDebugLockedCategoryButtonType::TriggerRight, EHazeDebugInputActivationType::PressOrHold);
			Handler.AddLockedCategoryButton(EHazeDebugLockedCategoryButtonType::MouseButtonLeft, EHazeDebugInputActivationType::PressOrHold);
		}
	}

	UFUNCTION()
	void ToggleDebugCamera()
	{
		Owner.SetCapabilityActionState(FCameraTags::DebugCamera, EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION()
	void DeactivateCamera()
	{
		Owner.SetCapabilityActionState(FCameraTags::DebugCamera, EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION()
	void Teleport()
	{
		if (TeleportHit.bBlockingHit)
		{
			if (Time::GetRealTimeSince(LastTeleportTime) < 0.3f)
			{
				// Second double tap, teleport other player
				NetTeleportOtherPlayer(TeleportHit.Location + DebugCamera.GetActorRotation().RotateVector(FVector(0.f, 100.f, 0.f)), TeleportHit.Normal ,DebugCamera.GetActorRotation().Yaw);
				LastTeleportTime = -BIG_NUMBER;
			}
			else 
			{
				// First tap, teleport owner
				NetTeleportOwner(TeleportHit.Location, TeleportHit.Normal, DebugCamera.GetActorRotation().Yaw);
				LastTeleportTime = Time::GetRealTimeSeconds();
			}
		}
	}

	UFUNCTION()
	void LockView()
	{
		if (bLockedView)
			NetUnlockView();
		else
			NetLockView();	
	}

	UFUNCTION()
	void IncreaseSpeed()
	{
		// Change speed multiplier permanently by tapping increase/decrease
		TapSpeedFactor = FMath::Min(TapSpeedFactor * 2.f, 64.f);
		IncreaseSpeedTimeStarted = Time::GetRealTimeSeconds();
		SpeedDirection = 0;
		SpeedDirectionMultiplier = 1.f;
	}

	UFUNCTION()
	void IncreaseSpeedHold()
	{
		SpeedDirection = 1;
		SpeedDirectionMultiplier = 1.f;
	}

	UFUNCTION()
	void IncreaseSpeedHoldMouse()
	{
		SpeedDirection = 1.f;
		SpeedDirectionMultiplier += 0.75f;
		MouseInputTime = 0.05f;
	}

	UFUNCTION()
	void DecreaseSpeed()
	{
		TapSpeedFactor = FMath::Max(TapSpeedFactor * 0.5f, 1.f / 64.f);	
		DecreaseSpeedTimeStarted = Time::GetRealTimeSeconds(); 
		SpeedDirection = 0;
		SpeedDirectionMultiplier = 1.f;
	}

	UFUNCTION()
	void DecreaseSpeedHold()
	{
		SpeedDirection = -1;
		SpeedDirectionMultiplier = 1.f;
	}

	UFUNCTION()
	void Decend()
	{
		WantedMoveDirection = -1;	
	}

	UFUNCTION()
	void Accend()
	{
		WantedMoveDirection = 1;
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		if(PlayerOwner == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(DebugCamera == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(FCameraTags::DebugCamera))
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateFromControl;
	}
 
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!AreDebugShortcutsEnabled())
			return EHazeNetworkDeactivation::DeactivateLocal; 

		if (WasActionStarted(FCameraTags::DebugCamera))
			return EHazeNetworkDeactivation::DeactivateFromControl; 

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DebugCamera.Activate(PlayerOwner.GetPlayerViewPoint());
		Owner.BlockCapabilities(CapabilityTags::MovementInput, this);
		Owner.BlockCapabilities(n"CameraNonControlled", this);
		Owner.BlockCapabilities(n"BlockedByDebugCamera", this);

		UCameraUserComponent UserComp = UCameraUserComponent::Get(Owner);
		if (UserComp != nullptr)
			UserComp.bUsingDebugCamera = true;

		bLockedView = false;
		HoldSpeedFactor.Value = 1.f;
		HoldSpeedFactor.Velocity = 0.f;
		TapSpeedFactor = 1.f;
		LastNetSyncedLocation = DebugCamera.GetActorLocation();
		LastNetSyncedRotation = DebugCamera.GetActorRotation();
		NetLagLocation.Value = LastNetSyncedLocation;
		NetLagLocation.Velocity = 0.f;
		NetLagRotation.Value = LastNetSyncedRotation;
		NetLagRotation.Velocity = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		DebugCamera.Deactivate(PlayerOwner.GetPlayerViewPoint());
		if (!bLockedView)
			PlayerOwner.UnblockCapabilities(CapabilityTags::MovementInput, this);

		Owner.UnblockCapabilities(n"CameraNonControlled", this);
		Owner.UnblockCapabilities(n"BlockedByDebugCamera", this);	

		UCameraUserComponent UserComp = UCameraUserComponent::Get(Owner);
		if (UserComp != nullptr)
			UserComp.bUsingDebugCamera = false;	
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (DebugCamera != nullptr)
			DebugCamera.DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float UndilatedDeltaTime = DeltaTime / Owner.GetActorTimeDilation();

		if (HasControl())
		{
			// Check where we would end up if we'd teleport the player right now
			TeleportHit = FHitResult();
			Camera::CheckCameraCollision(UHazeCameraComponent::Get(DebugCamera), 
										DebugCamera.GetActorLocation(), 
										DebugCamera.GetActorLocation() + DebugCamera.GetActorForwardVector() * 100000.f, 
										TeleportHit);

			// Debug draw subtle indication of where a teleport would place us
			if (TeleportHit.bBlockingHit && (TeleportHit.Location.DistSquared(DebugCamera.GetActorLocation()) > 100.f*100.f))
				System::DrawDebugPoint(TeleportHit.Location, 1.5f, FLinearColor(1.f, 0.f, 1.f));

			// Rotate camera
			const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
			FRotator CameraTurnRate = FRotator(180.f, 360.f, 0.f);
			FRotator RotationDelta = FRotator::ZeroRotator; 
			RotationDelta.Yaw = AxisInput.X * UndilatedDeltaTime * CameraTurnRate.Yaw;
			RotationDelta.Pitch = AxisInput.Y * UndilatedDeltaTime * CameraTurnRate.Pitch;
			DebugCamera.RotateCamera(RotationDelta);

			if(WantedMoveDirection > 0 && MoveUpAndDownDirection < 0)
				MoveUpAndDownDirection = FMath::FInterpConstantTo(MoveUpAndDownDirection, WantedMoveDirection, UndilatedDeltaTime, 5.f);
			else if(WantedMoveDirection < 0 && MoveUpAndDownDirection > 0)
				MoveUpAndDownDirection = FMath::FInterpConstantTo(MoveUpAndDownDirection, WantedMoveDirection, UndilatedDeltaTime, 5.f);
			else if(WantedMoveDirection == 0)
				MoveUpAndDownDirection = FMath::FInterpConstantTo(MoveUpAndDownDirection, WantedMoveDirection, UndilatedDeltaTime, 5.f);
			else
				MoveUpAndDownDirection = FMath::FInterpConstantTo(MoveUpAndDownDirection, WantedMoveDirection, UndilatedDeltaTime, 2.f);

			// Move camera
			if (!bLockedView)
			{
				// Speed multiplier is temporarily changed when increase/decrease is pressed
				if (SpeedDirection > 0)
					HoldSpeedFactor.AccelerateTo(MaxHoldSpeedFactor * SpeedDirectionMultiplier, 0.5f, UndilatedDeltaTime);
				else if (SpeedDirection < 0)
					HoldSpeedFactor.AccelerateTo(1.f / MaxHoldSpeedFactor, 0.5f, UndilatedDeltaTime);
				else 
					HoldSpeedFactor.AccelerateTo(1.f, 0.5f, UndilatedDeltaTime);

				// if (WasActionStarted(ActionNames::DebugCameraIncreaseSpeed))
				// 	IncreaseSpeedTimeStarted = Time::GetRealTimeSeconds();
				// if (WasActionStopped(ActionNames::DebugCameraIncreaseSpeed) && (Time::GetRealTimeSince(IncreaseSpeedTimeStarted) < TapDuration)) 
				// {
				// 	// Tapped increase
				// 	TapSpeedFactor = FMath::Min(TapSpeedFactor * 2.f, 64.f);	
				// 	HoldSpeedFactor.Value *= 0.5f;
				// 	Print("Debug camera speed factor: " + TapSpeedFactor);
				// }
				// if (WasActionStarted(ActionNames::DebugCameraDecreaseSpeed))
				// 	DecreaseSpeedTimeStarted = Time::GetRealTimeSeconds(); 
				// if (WasActionStopped(ActionNames::DebugCameraDecreaseSpeed) && (Time::GetRealTimeSince(DecreaseSpeedTimeStarted) < TapDuration)) 
				// {
				// 	// Tapped decrease
				// 	TapSpeedFactor = FMath::Max(TapSpeedFactor * 0.5f, 1.f / 64.f);	
				// 	HoldSpeedFactor.Value *= 2.f;
				// 	Print("Debug camera speed factor: " + TapSpeedFactor);
				// }

				// Change speed multiplier by the DebugCameraSpeed axis value (e.g. mouse wheel)
				float Acc = 0.2f;
				float SpeedAttributeFactor = 1.0f + (FMath::Sign(GetAttributeValue(AttributeNames::DebugCameraSpeed)) * Acc);
				
				float SpeedFactor = FMath::Clamp(HoldSpeedFactor.Value * TapSpeedFactor * SpeedAttributeFactor, 0.01f, 100.f);
				
				// Use raw movement stick instead of MovementDirection, as that is relative to desiredrotation which is 
				// (and should be) unaffected by debug camera
				FVector MoveInput = DebugCamera.GetActorRotation().RotateVector(GetAttributeVector(AttributeVectorNames::MovementRaw));
				MoveInput.Z += MoveUpAndDownDirection; // Up/Down movement is in world space (same as in editor)
				FVector MovementDelta = MoveInput * (BaseSpeed * SpeedFactor * UndilatedDeltaTime);
				DebugCamera.MoveCamera(MovementDelta);

				// Consume certain input so it won't be used for non-debug camera stuff. 
				// Note that capabilities that tick before this capability will still be able to use that input.
				// Also note that this is quite ad hoc: We do not know which attributes are set from input and will need to update this whenever input is added.

				TArray<EHazeDebugButtonType> DebugInputs;
				DebugInputs.Add(EHazeDebugButtonType::DUp);
				DebugInputs.Add(EHazeDebugButtonType::DDown);
				DebugInputs.Add(EHazeDebugButtonType::DLeft);
				DebugInputs.Add(EHazeDebugButtonType::DRight);
				DebugInputs.Add(EHazeDebugButtonType::TriggerLeft);
				DebugInputs.Add(EHazeDebugButtonType::TriggerRight);
				DebugInputs.Add(EHazeDebugButtonType::ShoulderLeft);
				DebugInputs.Add(EHazeDebugButtonType::ShoulderRight);

				TArray<FName> Exceptions;
				Exceptions.Add(ActionNames::ButtonMash);
				ConsumeActionsRelatedToDebugInputsWithActionExceptions(DebugInputs, Exceptions);
				
				//ConsumeAction(ActionNames::ButtonMash); // Don't consume this, this might be useful during debug camera usage
				//ConsumeAction(ActionNames::Cancel);  // Don't consume this, this might be useful during debug camera usage
			}
		}

		if (Network::IsNetworked())
		{
			if (HasControl())
			{
				NetSyncDelay -= UndilatedDeltaTime;
				if (NetSyncDelay < 0.f)
				{
					FRotator CamRot = DebugCamera.GetActorRotation();
					bool bUpdateRotation = !LastNetSyncedRotation.Equals(CamRot, 1.f);
					FVector CamLoc = DebugCamera.GetActorLocation();
					bool bUpdateLocation = !LastNetSyncedLocation.Equals(CamLoc, 1.f);
					if (bUpdateLocation && bUpdateRotation)
						NetSyncPosition(CamLoc, CamRot);
					else if (bUpdateRotation)
						NetSyncRotation(CamRot);
					else if (bUpdateLocation)
						NetSyncLocation(CamLoc);
				}	
			}
			else if (DebugCamera != nullptr)
			{
				// Remote side, accelerate towards synced rotation/location
				FVector CamLoc = DebugCamera.GetActorLocation();
				NetLagLocation.Value = CamLoc; // In case debug camera is teleported for some reason; normally not necessary
				NetLagLocation.AccelerateTo(LastNetSyncedLocation, 1.f, UndilatedDeltaTime);
				DebugCamera.MoveCamera(NetLagLocation.Value - CamLoc);

				FRotator CamRot = DebugCamera.GetActorRotation();
				NetLagRotation.Value = CamRot; 
				NetLagRotation.AccelerateTo(LastNetSyncedRotation, 1.f, UndilatedDeltaTime);
				DebugCamera.RotateCamera(NetLagRotation.Value - CamRot);
			}
		}

		// Reset at the end
		WantedMoveDirection = 0;
		if(MouseInputTime > 0)
		{
			MouseInputTime -= DeltaTime;
		}			
		else
		{
			SpeedDirectionMultiplier = 1.f;
			SpeedDirection = 0;
		}		
	}

	UFUNCTION(NetFunction)
	void NetLockView()
	{
		bLockedView = true;
		PlayerOwner.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(NetFunction)
	void NetUnlockView()
	{
		bLockedView = false;
		PlayerOwner.BlockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(NetFunction)
	void NetTeleportOwner(FVector Loc, FVector WorldUp, float Yaw)
	{
		TeleportOwner(Loc, WorldUp, Yaw);
	}

	UFUNCTION(NetFunction)
	void NetTeleportOtherPlayer(FVector Loc, FVector ImpactNormal, float Yaw)
	{
		TeleportOtherPlayer(Loc, ImpactNormal, Yaw);
	}

	protected void TeleportOwner(FVector Loc, FVector ImpactNormal, float Yaw)
	{
		PlayerOwner.TeleportActor(Location = Loc, Rotation = FRotator(0.f, Yaw, 0.f));
	}

	protected void TeleportOtherPlayer(FVector Loc, FVector ImpactNormal, float Yaw)
	{
		PlayerOwner.GetOtherPlayer().TeleportActor(Location = Loc, Rotation = FRotator(0.f, Yaw, 0.f));
	}

	
	UFUNCTION(NetFunction)
	void NetSyncPosition(const FVector& ControlLocation, const FRotator& ControlRotation)
	{
		LastNetSyncedLocation = ControlLocation;	
		LastNetSyncedRotation = ControlRotation;
		NetSyncDelay = NetSyncInterval;	
	}

	UFUNCTION(NetFunction)
	void NetSyncRotation(const FRotator& ControlRotation)
	{
		LastNetSyncedRotation = ControlRotation;	
		NetSyncDelay = NetSyncInterval;	
	}

	UFUNCTION(NetFunction)
	void NetSyncLocation(const FVector& ControlLocation)
	{
		LastNetSyncedLocation = ControlLocation;	
		NetSyncDelay = NetSyncInterval;	
	}
};
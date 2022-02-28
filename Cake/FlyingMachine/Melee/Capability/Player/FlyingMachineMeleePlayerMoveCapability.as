
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleePlayerComponent;
import Vino.Camera.Components.CameraUserComponent;
import Cake.FlyingMachine.Melee.Capability.Player.FlyingMachineMeleePlayerJumpCapability;

class UFlyingMachineMeleePlayerMoveCapability : UFlyingMachineMeleeCapabilityBase
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MeleeTags::Melee);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(MeleeTags::MeleeBlockedWhenGrabbed);
	
	default TickGroupOrder = 100;
	default TickGroup = ECapabilityTickGroups::LastMovement;

	default CapabilityDebugCategory = MeleeTags::Melee;

	AHazePlayerCharacter Player;
	UFlyingMachineMeleePlayerComponent PlayerMeleeComponent;
	UHazeCrumbComponent CrumbComp;

	EHazeMeleeMovementType LastMovementType = EHazeMeleeMovementType::Idling;
	bool LastFrameWasJumping;
	float LastMoveAmount = 0;

	/*  EDITABLE VARIABLES */
	const float ForwardSpeed = 600.f;
	const float BackwardSpeed = 600.f;
	const float ValidMoveInput = 0.7f;
	/** */

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerMeleeComponent = Cast<UFlyingMachineMeleePlayerComponent>(MeleeComponent);
		CrumbComp = UHazeCrumbComponent::Get(Player);

		SetStateMovementType(EHazeMeleeMovementType::Idling);
		FaceRight();

		Player.BlockCapabilities(n"FlyingMachine", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.UnblockCapabilities(n"FlyingMachine", this);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		SetStateMovementType(EHazeMeleeMovementType::Idling);
		LastMovementType = EHazeMeleeMovementType::Idling;
		LastFrameWasJumping = false;
		LastMoveAmount = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeMeleeTarget SquirrelTarget;
		bool bHasTarget = MeleeComponent.GetCurrentTarget(SquirrelTarget);

		// UPDATE FACEING
		if(MeleeComponent.IsGrounded())
		{
			if(bHasTarget)
			{
				if(SquirrelTarget.Distance.X > 10)
				{
					if(SquirrelTarget.bIsToTheRightOfMe)
						FaceRight();
					else
						FaceLeft();
				}
			}
			else if(IsActioning(n"DebugForceSwapFaceDirection"))
			{
				ConsumeAction(n"DebugForceSwapFaceDirection");
				if(IsFacingRight())
					FaceLeft();
				else
					FaceRight();
			}
		}

		// UPDATE MOVEMENT
		float MoveAmount = 0;
		FHazeMeleeInputAmount Input;
		bool bIsMovingBackwards = false;
		if(MeleeComponent.GetMovementInput(Input))
		{
			MoveAmount = UpdateMovement(DeltaTime, Input, bIsMovingBackwards, SquirrelTarget, bHasTarget);
		}

		LastMoveAmount = MoveAmount;

		if(LastMovementType != EHazeMeleeMovementType::Crouching)
		{
			Player.SetCapabilityAttributeValue(n"CanTriggerCrouchAudio", 1.f);		
		}

		MeleeComponent.AddDeltaMovement(n"MoveCapabilty", MoveAmount * DeltaTime, 0.f);
	}

	float UpdateMovement(float DeltaTime, FHazeMeleeInputAmount Input, bool& bMovingBackwards, FHazeMeleeTarget SquirrelTarget, bool bHasTarget)
	{
		float MoveAmount = 0.f;
		bMovingBackwards = false;
		if(MeleeComponent.HasHorizontalTranslation())
			return 0;

		const bool bIsJumping = GetStateMovementType() == EHazeMeleeMovementType::Jumping;
		if(bHasTarget)
		{
			if(SquirrelTarget.Distance.X <= PlayerMeleeComponent.ClosestMoveDistance && SquirrelTarget.bIsInFrontOfMe 
				&& !bIsJumping
				&& SquirrelTarget.MovementType != EHazeMeleeMovementType::Hanging
				&& SquirrelTarget.MovementType != EHazeMeleeMovementType::Jumping)
			{
				if(IsFacingRight())
				{
					if(Input.StickRawType == EHazeMeleeStickRawHorizontalInputType::Right)
						return 0;
				}
				else
				{
					if(Input.StickRawType == EHazeMeleeStickRawHorizontalInputType::Left)
						return 0;
				}
			}
		}

		float SpeedMultiplier = 1.f;
		if(bIsJumping)
			SpeedMultiplier = 1.7f;

		if(Input.StickRawType == EHazeMeleeStickRawHorizontalInputType::Right)
		{	
			if(IsFacingRight())
				MoveAmount = ForwardSpeed * SpeedMultiplier;
			else
			{
				bMovingBackwards = true;
				MoveAmount = BackwardSpeed;
			}			
		}	
		else if(Input.StickRawType == EHazeMeleeStickRawHorizontalInputType::Left)
		{
			if(!IsFacingRight())
				MoveAmount = -ForwardSpeed * SpeedMultiplier;
			else
			{
				bMovingBackwards = true;
				MoveAmount = -BackwardSpeed;
			}		
		}

		if(bIsJumping)
		{
			// This will make the jumping a bit less jittery
			if(LastFrameWasJumping)
			{
				if(FMath::Abs(MoveAmount) > 0)
					MoveAmount = FMath::FInterpTo(LastMoveAmount, MoveAmount, DeltaTime, 6.f);
				else
					MoveAmount = LastMoveAmount;		
			}

			if(FMath::Abs(MoveAmount) > 0 && !LastFrameWasJumping)
				LastFrameWasJumping = true;

			return MoveAmount;
		}

		LastFrameWasJumping = false;
		if(Input.StickType == EHazeMeleeStickInputType::Down ||
			Input.StickType == EHazeMeleeStickInputType::BwdDown ||
			Input.StickType == EHazeMeleeStickInputType::FwdDown )
		{
			ControlSetStateMovementType(EHazeMeleeMovementType::Crouching);
			MoveAmount = 0;
		}
		else
		{
			if(MoveAmount != 0)
			{
				ControlSetStateMovementType(EHazeMeleeMovementType::Walking);
			}
			else
			{
				ControlSetStateMovementType(EHazeMeleeMovementType::Idling);
			}
		}

		return MoveAmount;
	}

	void ControlSetStateMovementType(EHazeMeleeMovementType MoveType)
	{
		if(LastMovementType != MoveType)
		{
			FHazeDelegateCrumbParams Params;
			Params.AddNumber(n"MoveType", MoveType);
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_SetStateMovementType"), Params);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_SetStateMovementType(const FHazeDelegateCrumbData& CrumbData)
	{
		EHazeMeleeMovementType NewMoveType = EHazeMeleeMovementType(CrumbData.GetNumber(n"MoveType"));
		LastMovementType = NewMoveType;
		SetStateMovementType(NewMoveType);
	}
}

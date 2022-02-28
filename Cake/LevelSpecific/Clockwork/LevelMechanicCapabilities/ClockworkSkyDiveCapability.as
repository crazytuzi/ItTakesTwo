import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Clockwork.Components.ClockworkSkydivingComponent;
import Vino.Characters.PlayerCharacter;
import Peanuts.SpeedEffect.SpeedEffectStatics;

class UClockworkSkydiveCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"ClockworkSkydive");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	APlayerCharacter Player;
	UClockworkSkydivingComponent DiveComp;

	float NewRandomOffsetTimer;
	float RandomOffsetFrequency = 0.1f;
	FVector RandomLocOffset = FVector::ZeroVector;

	FHazeAcceleratedVector AcceleratedInput;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<APlayerCharacter>(Owner);
		Super::Setup(SetupParams);
		DiveComp = UClockworkSkydivingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(n"ClockworkSkydiving"))
        	return EHazeNetworkActivation::DontActivate;
        
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::MovementAction, this);

		NewRandomOffsetTimer = 0.f;
		FHazeAnimationDelegate BlendOutDelegate;
		BlendOutDelegate.BindUFunction(this, n"OnBlendedOut");
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), BlendOutDelegate, DiveComp.EnterAnim, false, EHazeBlendType::BlendType_Inertialization, 0.2f, 0.4f);
		Player.PlayCameraShake(DiveComp.CamShake);
		Player.PlayCameraShake(DiveComp.SlowCamShake);
		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 2.f;
		Player.ApplyCameraSettings(DiveComp.CamSetting, BlendSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
		Player.MeshOffsetComponent.OffsetRotationWithSpeed(FRotator(0.f, Player.CurrentlyUsedCamera.WorldRotation.Yaw, 0.f));
		
		Player.ClearCameraSettingsByInstigator(this);
		Player.StopAllCameraShakes();
		Player.StopBlendSpace();
	}

	UFUNCTION()
	void OnBlendedOut()
	{
		Player.PlayBlendSpace(DiveComp.BlendSpace);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	

		NewRandomOffsetTimer += DeltaTime;
		if(NewRandomOffsetTimer >= RandomOffsetFrequency)
		{
			float MaxOffset = 3.f;
			NewRandomOffsetTimer = 0.f;
			RandomLocOffset = FVector(FMath::RandRange(-MaxOffset, MaxOffset), FMath::RandRange(-MaxOffset, MaxOffset), FMath::RandRange(-MaxOffset, MaxOffset));
		}

		SpeedEffect::RequestSpeedEffect(Player, FSpeedEffectRequest(1.f, this));

		FVector Input = GetAttributeVector(AttributeVectorNames::LeftStickRaw);
		AcceleratedInput.AccelerateTo(Input, 2.f, DeltaTime);
		Player.SetBlendSpaceValues(AcceleratedInput.Value.X, AcceleratedInput.Value.Y);
		float ForceFeedbackStrength = (AcceleratedInput.Value.Y + 1.f) * 0.1f;
		//Print(""+ForceFeedbackStrength);
		Player.SetFrameForceFeedback(ForceFeedbackStrength, ForceFeedbackStrength);
		FHazeCameraSettings CamSettings;
		CamSettings.bUseFOV = true;
		CamSettings.FOV = 100 + AcceleratedInput.Value.Y * 20.f;
		FHazeCameraSpringArmSettings CamSpringSettings;
		CamSpringSettings.bUseIdealDistance = true;
		CamSpringSettings.IdealDistance = 75 + AcceleratedInput.Value.Y * -45.f;
		Player.ApplySpecificCameraSettings(CamSettings, FHazeCameraClampSettings(), CamSpringSettings, FHazeCameraBlendSettings(), this);


		FRotator TargetRot = FRotator(0.f, Player.CurrentlyUsedCamera.WorldRotation.Yaw, 0.f);

		FHazeFrameMovement FrameMove;
		FrameMove = MoveComp.MakeFrameMovement(n"SkyDive");
		MoveComp.SetTargetFacingRotation(TargetRot.Quaternion(), 1.5f);
		FrameMove.ApplyTargetRotationDelta();
		Player.MeshOffsetComponent.OffsetRotationWithSpeed(FRotator(AcceleratedInput.Value.Y * -15.f, Player.CurrentlyUsedCamera.WorldRotation.Yaw, AcceleratedInput.Value.X * 20.f));
		// Player.MeshOffsetComponent.OffsetLocationWithSpeed(Player.ActorLocation + (RandomLocOffset * (AcceleratedInput.Value.Y + 1.f)), 850.f);
		// Player.MeshOffsetComponent.OffsetLocationWithTime(Player.ActorLocation + (RandomLocOffset * (AcceleratedInput.Value.Y + 1.f)), 0.02f);


		FVector DeltaLoc;
		DeltaLoc += Player.MovementWorldUp * (-3650.f + -AcceleratedInput.Value.Y * 350.f) * DeltaTime;
		DeltaLoc += Player.ActorRightVector * AcceleratedInput.Value.X * 350.f * DeltaTime;

		FrameMove.ApplyDelta(DeltaLoc);
		MoveCharacter(FrameMove, n"");
		//Print(""+TargetRot);
		

	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{

	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		if(IsActive())
		{
			FString DebugText = "";
			if(HasControl())
			{
				DebugText += "Control Side\n";
			}
			else
			{
				DebugText += "Slave Side\n";
			}
			return DebugText;
		}

		return "Not Active";
	}
}
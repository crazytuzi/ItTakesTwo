
import Vino.Movement.Components.MovementComponent;

class UMovementDirectionInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(AttributeVectorNames::MovementDirection);
		
	default TickGroup = ECapabilityTickGroups::Input;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	FVector CurrentInput = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate()const
	{
		if(HasControl())
		{
			if(MoveComp != nullptr)
			{
				return EHazeNetworkActivation::ActivateLocal;
			}
		}
		else
		{
			if(CrumbComp != nullptr)
			{
				return EHazeNetworkActivation::ActivateLocal;
			}
		}

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate()const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Force tick when activated because all the calculation is done there,
		// and sometimes, we get activated from another capability unblocking.
		TickActive(Owner.GetActorDeltaSeconds());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FVector Dir = FVector::ZeroVector;
		ConsumeAttribute(AttributeVectorNames::MovementDirection, Dir);
	}

	FVector GetReplicatedInput()const
	{
		FHazeActorReplicationFinalized MoveParams;

		if(CrumbComp.GetCurrentReplicatedData(MoveParams))
		{
			if(MoveParams.GetActorReplicationType() == EHazeActorReplicationType::PlayerCharacter)
			{
				return MoveParams.GetReplicatedInput();
			}
			else
			{
				return MoveParams.Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
			}
		}
			
		return FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			// Calculate input based on controlrotation
			const FRotator ControlRotation = Owner.GetControlRotation();

			FVector Forward = ControlRotation.ForwardVector.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
			if (Forward.IsZero())
			{
				Forward = ControlRotation.UpVector.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
			}
			
			const FVector Up = MoveComp.WorldUp;
			const FVector Right = Up.CrossProduct(Forward) * FMath::Sign(ControlRotation.UpVector.DotProduct(Up));

			const FVector RawStick = GetAttributeVector(AttributeVectorNames::MovementRaw);
			CurrentInput = Forward * RawStick.X + Right * RawStick.Y;
		}
		else
		{
			CurrentInput = GetReplicatedInput();
		}

		Owner.SetCapabilityAttributeVector(AttributeVectorNames::MovementDirection, CurrentInput);
		CrumbComp.SetReplicatedInputDirection(CurrentInput);

		if(IsDebugActive())
		{
			const FVector DebugLocation = Owner.GetActorLocation() + (MoveComp.WorldUp * 100.f);
			System::DrawDebugArrow(DebugLocation, DebugLocation + (CurrentInput * 200.f), 30.f, FLinearColor::LucBlue, Duration = 0.f, Thickness = 2.f);
		}
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString Str = "InputDir: " + CurrentInput.ToString();
		Str += "\n";
	
		return Str;
	}
};

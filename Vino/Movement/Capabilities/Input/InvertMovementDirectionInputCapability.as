
import Vino.Movement.Components.MovementComponent;

class UInvertMovementDirectionInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(AttributeVectorNames::MovementDirection);
		
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 99;

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

		SetMutuallyExclusive(AttributeVectorNames::MovementDirection, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FVector Dir = FVector::ZeroVector;
		ConsumeAttribute(AttributeVectorNames::MovementDirection, Dir);

		SetMutuallyExclusive(AttributeVectorNames::MovementDirection, false);
	}

	FVector GetReplicatedInput()const
	{
		FHazeActorReplicationFinalized MoveParams;
		CrumbComp.GetCurrentReplicatedData(MoveParams);

		return MoveParams.Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
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
			const FVector Right = Up.CrossProduct(Forward);

			const FVector RawStick = GetAttributeVector(AttributeVectorNames::MovementRaw);
			CurrentInput = Forward * -RawStick.X + Right * RawStick.Y;
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

UFUNCTION()
void InvertForwardInput(AHazePlayerCharacter Player)
{
	Player.AddCapability(UInvertMovementDirectionInputCapability::StaticClass());
}

UFUNCTION()
void UninvertForwardInput(AHazePlayerCharacter Player)
{
	Player.RemoveCapability(UInvertMovementDirectionInputCapability::StaticClass());
}
import Vino.Movement.Components.MovementComponent;


class UDebugMovementInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(AttributeVectorNames::MovementDirection);
		
	default TickGroup = ECapabilityTickGroups::Input;

	UHazeMovementComponent MoveComp;
	FVector StartLocation = FVector::ZeroVector;
	FVector CurrentInput = FVector::ZeroVector;
	FRotator CurrentRotation = FRotator::ZeroRotator;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		const FVector CurrentLocation = Owner.GetActorLocation();
		StartLocation.Z = CurrentLocation.Z;

		const FRotator TargetRotation = (StartLocation - CurrentLocation).ToOrientationRotator();
		const float Distance = CurrentLocation.Distance(StartLocation);
		if(Distance < 100.f )
		{
			CurrentRotation.Yaw += 100.f * DeltaTime;
		}
		else if(Distance < 1000.f )
		{
			CurrentRotation = FMath::RInterpTo(CurrentRotation, TargetRotation, DeltaTime, 2.f).GetNormalized();
		}
		else
		{
			CurrentRotation = FMath::RInterpTo(CurrentRotation, TargetRotation, DeltaTime, FMath::Max(Distance / 2000, 4.f)).GetNormalized();
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(HasControl())
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FVector Dir = FVector::ZeroVector;
		ConsumeAttribute(AttributeVectorNames::MovementDirection, Dir);
		StartLocation = Owner.GetActorLocation();
	}

	FVector GetStickInput()
	{
		if(HasControl())
		{
			if(MoveComp.IsGrounded())
			{
				return CurrentRotation.Vector();
			}		
		}
		
		return FVector::ZeroVector;
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Calculate input based on controlrotation
		FRotator ControlRotation = FRotator::ZeroRotator;
		ControlRotation.Yaw = Owner.GetControlRotation().Yaw;
		
		CurrentInput = ControlRotation.RotateVector(GetStickInput());
		
		// Feed in the input direction
		Owner.SetCapabilityAttributeVector(AttributeVectorNames::MovementDirection, CurrentInput);

		if(IsDebugActive())
		{
			const FVector DebugLocation = Owner.GetActorLocation() + (MoveComp.WorldUp * 100.f);
			System::DrawDebugArrow(DebugLocation, DebugLocation + (CurrentInput * 200.f), 10.f, FLinearColor::White, Duration = 0.f);
		}
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		return "Debug Input: " + CurrentInput.ToString();
	}
};
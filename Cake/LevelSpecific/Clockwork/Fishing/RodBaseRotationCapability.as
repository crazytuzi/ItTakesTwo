import Cake.LevelSpecific.Clockwork.Fishing.RodBase;

class URodBaseRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(n"RodBaseRotationCapability");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ARodBase RodBase;

	//*** ROTATION ***//
	float RotationSpeed;
	float RotationMultiplier = 45.f;

	//*** ROTATION ***//
	FHazeAcceleratedFloat AccelInput;
	float NetInput;

	//*** NETWORKING ***//
	FHazeAcceleratedRotator AcceleratedRotationSpeed;
	FRotator NetRotationValue;

	float NetworkTime;
	float NetworkRate = 0.4f;
	float NetworkAcceleration = 3.1f;

	bool bStartedRotating;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		RodBase = Cast<ARodBase>(Owner);
		NetRotationValue = RodBase.BaseRoot.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (HasControl())
		{
			ReadPlayerInput(DeltaTime);

			FRotator RotationYaw = FRotator(0,RotationSpeed,0);
			FRotator NewRot = RodBase.BaseRoot.RelativeRotation + (RotationYaw * DeltaTime);
			RodBase.BaseRoot.SetRelativeRotation(NewRot);

			//Find way to set gear rotation as well based of same values
				
			if (NetworkTime <= System::GameTimeInSeconds)
			{
				NetworkTime = System::GameTimeInSeconds + NetworkRate;
				NetRodRotationSpeed(NewRot);
				
				if (RodBase.PlayerComp != nullptr)
					NetPlayerInput(RodBase.PlayerComp.TargetRotationInput);
			}
		}
		else
		{
			AcceleratedRotationSpeed.AccelerateTo(NetRotationValue, NetworkAcceleration, DeltaTime);
			AccelInput.AccelerateTo(NetInput, NetworkAcceleration, DeltaTime);

			if (RodBase.PlayerComp != nullptr)
				RodBase.PlayerComp.TargetRotationInput = AccelInput.Value;
			
			RodBase.BaseRoot.RelativeRotation = AcceleratedRotationSpeed.Value;
		}
	}

	void ReadPlayerInput(float DeltaTime)
	{
		if (RodBase.PlayerComp != nullptr)
		{
			if (RodBase.PlayerComp.InputValue != 0.f)
			{
				RodBase.PlayerComp.TargetRotationInput = FMath::FInterpTo(RodBase.PlayerComp.TargetRotationInput, RodBase.PlayerComp.InputValue, DeltaTime, RodBase.PlayerComp.InterpSpeed);
			
				if (!bStartedRotating)
				{
					RodBase.AudioRodRotationStart();
					bStartedRotating = true;
				}
			}
			else
			{
				if (bStartedRotating)
				{
					RodBase.AudioRodRotationEnd();
					bStartedRotating = false;
				}
				
				RodBase.PlayerComp.InterpSpeed = RodBase.PlayerComp.DefaultInterpSpeed;
				RodBase.PlayerComp.TargetRotationInput = FMath::FInterpTo(RodBase.PlayerComp.TargetRotationInput, 0.f, DeltaTime, RodBase.PlayerComp.InterpSpeed);
			}

			RotationSpeed = RotationMultiplier * RodBase.PlayerComp.TargetRotationInput;
		}	
		else
		{	
			RotationSpeed = FMath::FInterpTo(RotationSpeed, 0.f, DeltaTime, 3.7f);
		}

		float AbsRot = FMath::Abs(RotationSpeed);
		float AbsRotFinal = AbsRot / RotationMultiplier;
		RodBase.AudioRotatingRodBase(AbsRotFinal);
	}
	
	UFUNCTION(NetFunction)
	void NetRodRotationSpeed(FRotator ToRotation)
	{	
		NetRotationValue = ToRotation;
	}

	UFUNCTION(NetFunction)
	void NetPlayerInput(float Value)
	{
		NetInput = Value;
	}
}
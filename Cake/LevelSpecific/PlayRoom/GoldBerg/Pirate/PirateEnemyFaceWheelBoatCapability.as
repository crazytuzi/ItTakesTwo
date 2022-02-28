import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateEnemyComponent;

class UPirateEnemyFaceWheelBoatCapability : UHazeCapability
{
    default CapabilityTags.Add(n"PirateEnemy");
	
	UPirateEnemyComponent EnemyComp;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		EnemyComp = UPirateEnemyComponent::Get(Owner);		
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if(EnemyComp.RotationRoot == nullptr)
        	return EHazeNetworkActivation::DontActivate; 

        return EHazeNetworkActivation::ActivateLocal; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        if(EnemyComp.RotationRoot == nullptr)
            return EHazeNetworkDeactivation::DeactivateLocal;
				
        return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		if(EnemyComp.bFacePlayerFromStart)
		{
			FRotator TargetRotation = EnemyComp.RotationRoot.WorldRotation;
			if(EnemyComp.bFacePlayer && EnemyComp.WheelBoat != nullptr)
			{
				FVector DirToWheelBoat = EnemyComp.WheelBoat.ActorLocation - EnemyComp.RotationRoot.WorldLocation;
				DirToWheelBoat.Normalize();
				TargetRotation = Math::MakeRotFromX(DirToWheelBoat);
			}
			else
			{
				TargetRotation = Owner.GetActorRotation();
			}

			EnemyComp.RotationRoot.SetWorldRotation(TargetRotation);
		}
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		FRotator TargetRotation = EnemyComp.RotationRoot.WorldRotation;
		if(EnemyComp.bFacePlayer && EnemyComp.WheelBoat != nullptr)
		{
			FVector DirToWheelBoat = EnemyComp.WheelBoat.ActorLocation - EnemyComp.RotationRoot.WorldLocation;
			DirToWheelBoat.Normalize();
			TargetRotation = Math::MakeRotFromX(DirToWheelBoat);
		}
		else
		{
			TargetRotation = Owner.GetActorRotation();
		}

		FRotator NewRotation = FMath::RInterpTo(EnemyComp.RotationRoot.WorldRotation, TargetRotation, DeltaTime, 3.5f);
		NewRotation.Pitch = 0.0f;
		EnemyComp.RotationRoot.SetWorldRotation(NewRotation);

    }
};
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Peanuts.DamageFlash.DamageFlashStatics;

class UCastleEnemyTargetDummyReactCapability : UHazeCapability
{	
    ACastleEnemy Enemy;

	FHazeAcceleratedRotator AcceleratedRotation;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
        Enemy.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
    }

    UFUNCTION()
    void OnTakeDamage(ACastleEnemy DamagedEnemy, FCastleEnemyDamageEvent Event)
    {
		if (DamagedEnemy.bKilled)
			return;

		if (!Event.HasDirection())
			return;

		// The rotation added I believe is wrong, but it works for now
		FVector Axis = FVector::UpVector.CrossProduct(Event.DamageDirection).GetSafeNormal();
		Axis = Enemy.Mesh.WorldTransform.TransformVector(Axis);
		
		FRotator RotationImpulse = FMath::RotatorFromAxisAndAngle(Axis, 500.f);
		AcceleratedRotation.Velocity += RotationImpulse;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (!Enemy.bKilled)
            return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;			
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AcceleratedRotation.SpringTo(FRotator::ZeroRotator, 800.f, 0.1f, DeltaTime);
		Enemy.Mesh.SetRelativeRotation(AcceleratedRotation.Value);
	}
}
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.ControllableUFO;
class UPlayRoomFlyingSaucerTurretAnimInstance : UHazeAnimInstanceBase
{

	UPROPERTY(BlueprintReadOnly)
    FHazePlaySequenceData Fire;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator TurretRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bFiredThisTick;

	AControllableUFO ControllableUFO;
    
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (OwningActor == nullptr)
            return;

		ControllableUFO = Cast<AControllableUFO>(OwningActor.GetAttachParentActor());
	}


    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (ControllableUFO == nullptr)
            return;

		// Check if player fired a shot this tick
		bFiredThisTick = GetAnimBoolParam(n"Fire", true);

		// Calculate the rotation for the turret
		const FVector HitLocation = GetAnimVectorParam(n"HitLocation", true);
		const FVector TurretLocation = ControllableUFO.LaserGun.LaserGunSkelMesh.GetSocketLocation(n"Turret");
		const FTransform BaseTransform = ControllableUFO.LaserGun.LaserGunSkelMesh.GetSocketTransform(n"Root");
		
		const FVector UpVector = (BaseTransform.Location - TurretLocation);
		const FVector HitDeltaVector = TurretLocation - HitLocation;
		FRotator WantedTurretRotation = Math::MakeRotFromXZ(HitDeltaVector, -UpVector);
		WantedTurretRotation = BaseTransform.InverseTransformRotation(WantedTurretRotation);
		
		TurretRotation.Pitch = FMath::FInterpTo(TurretRotation.Pitch, -WantedTurretRotation.Pitch, DeltaTime, 5.f);

    }

}
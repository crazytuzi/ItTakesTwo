import Peanuts.Animation.Features.Tree.LocomotionFeatureTreeFlyingMachineTurret;
import Cake.FlyingMachine.Gunner.FlyingMachineGunnerComponent;
import Peanuts.Animation.AnimInstances.Tree.TreeFlyingMachineTurretAnimInstance;

class UTreeFlyingMachineTurretPlayerAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureTreeFlyingMachineTurret Feature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bFireLeftThisTick;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bFireRightThisTick;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayFireRightAnim;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayFireLeftAnim;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bSyncAnimations = false;
	
	AFlyingMachineTurret Turret;
	UTreeFlyingMachineTurretAnimInstance TurretAnimInstance;

	float AimYaw, AimPitch;


    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        Feature = Cast<ULocomotionFeatureTreeFlyingMachineTurret>(GetFeatureAsClass(ULocomotionFeatureTreeFlyingMachineTurret::StaticClass()));
		const UFlyingMachineGunnerComponent GunnerComponent = Cast<UFlyingMachineGunnerComponent>(OwningActor.GetComponentByClass(UFlyingMachineGunnerComponent::StaticClass()));
		if (GunnerComponent == nullptr)
			return;
		Turret = GunnerComponent.CurrentTurret;
		TurretAnimInstance = Cast<UTreeFlyingMachineTurretAnimInstance>(Turret.Mesh.AnimInstance);
		
    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (Turret == nullptr)
            return;

		// Read variables from the turret
		bPlayFireRightAnim = TurretAnimInstance.bPlayFireRightAnim;
		bPlayFireLeftAnim = TurretAnimInstance.bPlayFireLeftAnim;
		bFireLeftThisTick = TurretAnimInstance.bFireLeftThisTick;
		bFireRightThisTick = TurretAnimInstance.bFireRightThisTick;

		// Calculate rotation rate for the blendspace values
		BlendspaceValues.X = FMath::Clamp(((AimYaw - Turret.AimYaw) / -DeltaTime) / 130.f, -1.f, 1.f);
		BlendspaceValues.Y = FMath::Clamp(((AimPitch - Turret.AimPitch) / -DeltaTime) / 50.f, -1.f, 1.f);
		
		AimYaw = Turret.AimYaw;
		AimPitch = Turret.AimPitch;
		
		bSyncAnimations = TurretAnimInstance.bSyncAnimations;
		if (bSyncAnimations)
		{
			if (TopLevelGraphRelevantStateName == n"Sync")
				TurretAnimInstance.bPlayerIsReady = true;
		}
    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
        return true;
    }

}
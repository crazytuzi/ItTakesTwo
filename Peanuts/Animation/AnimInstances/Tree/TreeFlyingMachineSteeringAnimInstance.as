import Peanuts.Animation.Features.Tree.LocomotionFeatureTreeFlyingMachineSteering;
import Cake.FlyingMachine.FlyingMachine;
import Cake.FlyingMachine.Pilot.FlyingMachinePilotComponent;
import Peanuts.Animation.AnimInstances.Tree.TreeFlyingMachineAnimInstance;

class UTreeFlyingMachineSteeringAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureTreeFlyingMachineSteering Feature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bTookDamageThisTick;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bBoostMeleeFight;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bSyncAnimations = false;

	AFlyingMachine FlyingMachine;
	UTreeFlyingMachineAnimInstance FlyingMachineAnimInstance;

	default BlendTime = 0.f;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        Feature = Cast<ULocomotionFeatureTreeFlyingMachineSteering>(GetFeatureAsClass(ULocomotionFeatureTreeFlyingMachineSteering::StaticClass()));
		const UFlyingMachinePilotComponent PilotComponent = Cast<UFlyingMachinePilotComponent>(OwningActor.GetComponentByClass(UFlyingMachinePilotComponent::StaticClass()));
		if (PilotComponent == nullptr)
			return;
		FlyingMachine = PilotComponent.CurrentMachine;
		FlyingMachineAnimInstance = Cast<UTreeFlyingMachineAnimInstance>(FlyingMachine.Mesh.AnimInstance);
		
    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (FlyingMachineAnimInstance == nullptr)
            return;

		

		BlendspaceValues = FlyingMachineAnimInstance.BlendspaceValues;
		bTookDamageThisTick = FlyingMachineAnimInstance.bTookDamageThisTick;
		bBoostMeleeFight = FlyingMachineAnimInstance.bBoostMeleeFight;
		
		bSyncAnimations = FlyingMachineAnimInstance.bSyncAnimations;
		if (bSyncAnimations)
		{
			if (TopLevelGraphRelevantStateName == n"Sync")
				FlyingMachineAnimInstance.bPilotIsReady = true;
		}

    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
        return true;
    }


}
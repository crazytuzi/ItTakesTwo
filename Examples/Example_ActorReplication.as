/*
    This is a the collected examples that you can do with actor replication
*/

/* This actor continas examples of how you setup network replication */
class AExampleReplicatedActor : AHazeActor
{
	/* You can specify how much actor params you want to replicatet to the remote side.
	 * The default is 'simple'; this will only send over the location and rotation.
	 * 'MovingActor' also includes the velocity
	 * 'PhysicsSimulation' also includes the agular velocity
	 * 'PlayerCharacter' includes all the above and also the actual world location even if it is relative to something
	 * 'SubActor' will, if attached, used the parents replicationdata
	*/
	default ReplicateAsPlayerCharacter();
	default ReplicateAsMovingActor();
	default ReplicateAsPhysicsObject();
	default ReplicateAsSubActor();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		/* All actors have a 'control' side and a 'remote' side.
		 * The controlside creates the replication information and sends it over to the remote side.
		 * You can change the controlside to have the same controlside as another actor.
		 * OBS! This function needs to be called on both side on the same object.
		 * In this example, we make this object have the same controlside as cody.
		 * OBS! calling this will also set the remote side, if the object passed in is on the remote side.
		*/
		SetControlSide(Game::GetCody());


		/* Adding a crumb component to the actor will make the replication
		 * more correct to the timing on the controlside, but also add more delay.
		 * Adding a crumb component is needed if you want to use the crumb replication in the capabilities. (See: UExampleReplicatedCapability)
		*/
		UHazeCrumbComponent CrumbComponent = UHazeCrumbComponent::GetOrCreate(Owner);

		/* You can extend the actor replication with a custom vector and a custom rotator.
		 * This is done by making the crumb component include them in the replication.
		 * The vector and rotator don't have any defined functionallity and can be use for whatever you need it for.
		 * Making them 'bReplicateRelativeToParent' will replicated the vector and rotator in the ownerspace.
		*/
		CrumbComponent.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this, bReplicateRelativeToParent = false);
		CrumbComponent.RemoveCustomParamsFromActorReplication(this);

		/* You can use delegate crumbs to send over custom data to the remoteside.
		 * The 'CrumbParams' contains a blackboard so you are free to add what you need outside the regular actor replication
		*/
		FHazeDelegateCrumbParams CrumbParams;
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_ExampleCrumbDelegateFunction"), CrumbParams);


		/* If you attach the actor to something, 
		 * the replication params will be replicated relative to that actor.
		*/
		AttachToActor(Game::GetCody());

		/* Adding a movement component will replicated over the velocity in the movement component
		 * If the movement component is grounded, the replication information will be relative to the floor. (Like an attachment)
		*/
		UHazeBaseMovementComponent MoveComponent = UHazeBaseMovementComponent::GetOrCreate(Owner);

		/* Actor replication contains 2 validation values; Level and Number
		 * Sending something unreliable will increase the Number;
		 * Sending something reliable will reset the Number and increase the Level.
		 * A replication received and tagged with a lower number, or a lower level will be discarded.
		 * You can force a Level increase by calling 'TriggerMovementTransition'.
		 * OBS! This functions needs to happen on both side.	 
		*/
		TriggerMovementTransition(this);

		/* You can change how the replication information is sent over to the remote side in the crumbs.
		 * This is done by using a CustomWorldCalculator.
		 * This class will hijack the replication steps so you can send over what information you want.
		*/
		CrumbComponent.MakeCrumbsUseCustomWorldCalculator(UExampleReplicatedCapability::StaticClass(), this);
		CrumbComponent.RemoveCustomWorldCalculator(this);
	}
	

	/* The example function called the the actor sends over a delegate crumb */
	UFUNCTION(NotBlueprintCallable)
	void Crumb_ExampleCrumbDelegateFunction(FHazeDelegateCrumbData CrumbData)
	{

	}

}

/* This capability contains examples on what the crumbs function does. */
class UExampleReplicatedCapability : UHazeCapability
{  
	// OBS! All these functions can also be added to the 'ControlPreDeactivation'
	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		/* This will make the actor activate the capability without using the transform information replicated from the controlside */
		ActivationParams.SetCrumbTransformValidation(EHazeActorReplicationSyncTransformType::NoMovement);

		// This is the same as setting 'NoMovement'
		ActivationParams.DisableTransformSynchronization();


		/* This will make the actor, smooth teleport to replicated transform. */
		ActivationParams.SetCrumbTransformValidation(EHazeActorReplicationSyncTransformType::SmoothTeleport);

		/* This can only be used if you have a crumbcomponent, else it will be treated as 'NoMovement'
		 * This will make the actor traverse the crumbtrail and be as close to the replicated transform as it can.
		 * This don't garantee that the transform will be exactly the same.
		 * This is the default behaviour of capabilities
		*/
		ActivationParams.SetCrumbTransformValidation(EHazeActorReplicationSyncTransformType::AttemptWait);
		
		/* This can only be used if you have a crumbcomponent, else it will be treated as 'SmoothTeleport'
		 * This will make the actor traverse the crumbtrail.
		 * When the crumb is reached, it will also smooth teleport the actor to the exact replicated transform
		*/
		ActivationParams.SetCrumbTransformValidation(EHazeActorReplicationSyncTransformType::AttemptWait_SmoothTeleport);
		

	
		/* This is the same as setting 'SmoothTeleport'. 
		 * If you have a crumb component it will be 'AttemptWait_SmoothTeleport'
		*/
		ActivationParams.EnableTransformSynchronizationWithTime();
	}

}


/* This ReplicationLocationCalculator contains examples how to modify the actor replication information. */
class UHazeExampleReplicationLocationCalculator : UHazeReplicationLocationCalculator
{
	/* This function is called when you use the 'MakeCrumbsUseCustomWorldCalculator' on the crumb component. */
	UFUNCTION(BlueprintOverride)
	void OnSetup(AHazeActor Owner, USceneComponent InRelativeComponent)
	{

	}

	/* This function is called whenever a crumb transition is made. */
	UFUNCTION(BlueprintOverride)
	void OnReset(FHazeActorReplicationFinalized CurrentParams)
	{

	}

	/* This function is called when the control side is setting up information that is going to be sent over to the remote side.
	 * In here, you can modify all the data that is replicated.
	 * OBS! Not all data in here might actually be replicated. It depends on the 'EHazeActorReplicationInitializeType', if you have a movementcomponent, etc.
	*/
	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationSend(FHazeActorReplicationCustomizable& OutTargetParams) const
	{

	}

	/* This function is called when the remote side receives the replicated information from the controlside created in the 'ProcessActorReplicationSend'
	 * The target params are filled with the correct information so you only have to change what you want to modify.
	*/
	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationReceived(FHazeActorReplicationFinalized FromParams, FHazeActorReplicationCustomizable& TargetParams)
	{
		
	}

	/* This function is called when the target params are beeing transformed into the params the actor should use this frame. */
	UFUNCTION(BlueprintOverride)
	void ProcessFinalReplicationTarget(FHazeActorReplicationCustomizable& TargetParams) const
	{
	
	}

	/* This function is called at the end of the frame, as long as the locator is active. */
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime, FHazeActorReplicationFinalized CurrentParams)
	{
			
	}
}

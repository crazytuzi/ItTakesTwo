import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCranePlatformInteraction;

class UDinoCraneCageMover : USceneComponent
{
	UPROPERTY()
	ADinoCranePlatformInteraction LinkedDinoCrane;

	UPROPERTY()
	AHazeInteractionActor LinkedInteraction;

    UPROPERTY(Meta = (MakeEditWidget))
    FTransform EndTransform;

	FTransform StartTransform;
	float TotalDistance;

	UPROPERTY()
	AActor ActorToMove;

	//Functionality not yeet implemented.
	bool IsInteracting;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartTransform = Owner.ActorTransform;
		TotalDistance = Owner.ActorTransform.Location.Distance(Owner.ActorTransform.TransformPosition(EndTransform.Location));

		LinkedDinoCrane.StartInteracting.AddUFunction(this, n"StartedInteracting");
		LinkedDinoCrane.EndedInteracting.AddUFunction(this, n"StoppedInteracting");

	}

	UFUNCTION()
	void StartedInteracting()
	{
		IsInteracting = true;
	}

	UFUNCTION()
	void StoppedInteracting()
	{
		IsInteracting = false;
	}

	float GetMovedPercentage() property
	{
		float Distance = LinkedDinoCrane.Spline.GetDistanceAlongSplineAtWorldLocation(LinkedDinoCrane.ActorLocation);

		float Percentage = Distance / LinkedDinoCrane.Spline.SplineLength;

		return Percentage;
	}

	FVector GetWorldLocation()
	{
		FVector DirectionToMove = (Owner.ActorTransform.TransformPosition(EndTransform.Location)) - Owner.ActorLocation;
		DirectionToMove.Normalize();

		FVector EndLocation = StartTransform.Location + DirectionToMove * TotalDistance * MovedPercentage;
		return EndLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float deltaTime)
	{
		ActorToMove.SetActorLocation(WorldLocation);

		bool isInteractionDisabled = LinkedInteraction.IsInteractionDisabled();

		if (MovedPercentage > 0.9f && isInteractionDisabled)
		{
			LinkedInteraction.EnableInteraction(n"StartDisabled");
		}
		else if (MovedPercentage < 0.8f && !isInteractionDisabled)
		{
			LinkedInteraction.DisableInteraction(n"StartDisabled");
		}
	}
}
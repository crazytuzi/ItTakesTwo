import Cake.SteeringBehaviors.BoidShapeComponent;

class ABoidArea : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = RootComp)
	UBoidShapeComponent Shape;

	default Shape.Radius = 9000.0f;

	bool IsPointOverlapping(FVector Point) const
	{
		return Shape.IsPointOverlapping(Point);
	}

	FVector GetRandomPointInsideShape() const property
	{
		return Shape.RandomPointInsideShape;
	}
}

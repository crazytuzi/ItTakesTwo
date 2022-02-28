import Cake.SteeringBehaviors.BoidShapeComponent;

import void RegisterBoidObstacle(UBoidObstacleComponent) from "Cake.SteeringBehaviors.BoidObstacleStatics";
import void UnregisterBoidObstacle(UBoidObstacleComponent) from "Cake.SteeringBehaviors.BoidObstacleStatics";

class UBoidObstacleComponent : UBoidShapeComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RegisterBoidObstacle(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		UnregisterBoidObstacle(this);
	}
}

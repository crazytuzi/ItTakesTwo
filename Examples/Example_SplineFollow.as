/* Spline follow is best made by using a spline follow component
 *
*/

class AExampleSplineFollowActorType : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeSplineFollowComponent SplineFollowComponent;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

	UPROPERTY(EditInstanceOnly)
	UHazeSplineComponentBase TheSplineWeShouldFollow;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{		
		// This will setup the spline in the splinefollow component
		bool bMoveForwardOnSpline = true;
		SplineFollowComponent.ActivateSplineMovement(TheSplineWeShouldFollow, bMoveForwardOnSpline);

		// To have the actor replicate the spline, you need to call this row
		SplineFollowComponent.IncludeSplineInActorReplication(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		// To remote it from replication, use this
		SplineFollowComponent.RemoveSplineFromActorReplication(this);

		// Clear the current spline
		SplineFollowComponent.DeactivateSplineMovement();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		/* OBS!, you don't have to replicate the spline movement.
		 * You can just update the splinemovement on both sides
		*/
		if(HasControl())
		{	
			// The resault is stored in a 'FHazeSplineSystemPosition'. This struct gives you access to more functions.
			FHazeSplineSystemPosition SplinePosition;

			// You update the splinemovement using a delta amount.
			const float MoveAmount = 200 * DeltaTime;

			/* This will update the internal spline position data.
			 *  The outresult is a status 
			*/
			const EHazeUpdateSplineStatusType UpdateStatus = SplineFollowComponent.UpdateSplineMovement(MoveAmount, SplinePosition);

			// The move happend all the way
			EHazeUpdateSplineStatusType::Valid;

			// The move didn't happen
			EHazeUpdateSplineStatusType::Invalid;
			EHazeUpdateSplineStatusType::Unreachable;

			// The move happen but it reached the end
			EHazeUpdateSplineStatusType::AtEnd;

			// Spline position has a bunch of helper.
			SplinePosition.GetWorldLocation();
			SplinePosition.GetWorldRotation();
			// ETC...

			// Leaving a crumb with the 'IncludeSplineInActorReplication' will make the actor follow the spline
			CrumbComponent.LeaveMovementCrumb();
		}
		else
		{
			// Consume the crumb trail as usual but apply it to the spline to get the current location on the spline instead
			FHazeActorReplicationFinalized Replication;
			CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, Replication);
			const EHazeUpdateSplineStatusType UpdateStatus = SplineFollowComponent.UpdateReplicatedSplineMovement(Replication);
		}

		// The position we are currently at on the spline
		FHazeSplineSystemPosition FinalSplinePosition = SplineFollowComponent.GetPosition();
		SetActorLocation(FinalSplinePosition.GetWorldLocation());
	}
}
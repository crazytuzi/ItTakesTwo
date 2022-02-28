import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateOceanStreamActor;
import Vino.Tutorial.TutorialStatics;

event void FOnWheelBoatEnteredStream();
event void FOnWheelBoatExitedStream();

class UWheelBoatStreamComponent : UHazeSplineFollowComponent
{
	UPROPERTY()
	FOnWheelBoatEnteredStream OnWheelBoatEnteredStream;	

	UPROPERTY()
	FOnWheelBoatExitedStream OnWheelBoatExitedStream;
	
	float StreamRotationForce = 0.025f;
	float AdditiveRotationForce = 0.5f;
	float DecrementalRotationForce = -0.5f;

	UPROPERTY(NotEditable)
	APirateOceanStreamActor LockedStream;
	FVector StreamDirection;
	FVector PositionClosestToBoat;
	UCapsuleComponent Collision;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Collision = UCapsuleComponent::Get(Owner);
	}

	void UpdateDirectionUsingStreamsInRange(float DeltaTime, float Range, FVector Velocity, APirateOceanStreamActor& OutBestStream)
	{
		FVector BoatLocation = Owner.GetActorLocation();
	
		if(LockedStream == nullptr || LockedStream.Spline == nullptr)
		{
			StreamDirection = FVector::ZeroVector;
			PositionClosestToBoat = BoatLocation;
			return;
		}

		FVector WantedStreamDirection;

		const float VelocityAlpha = FMath::Pow(FMath::Min(Velocity.Size() / 100.f, 1.f), 2.f);
		const float MaxDistance = 5000.f;
		TArray<APirateOceanStreamActor> Streams;
		int ClosestIndex;
		float BestScore;
		bool bForceNewSpline = false;
		{
			FHazeSplineSystemPosition LockedStreamPosition = LockedStream.Spline.GetPositionClosestToWorldLocation(BoatLocation, true);
			UpdateSplineMovementFromPosition(LockedStreamPosition);
			PositionClosestToBoat = LockedStreamPosition.WorldLocation;

			Streams.Add(LockedStream);
			ClosestIndex = 0;

			float LockedDistanceMultiplier = 1 - FMath::Min(BoatLocation.Distance(LockedStreamPosition.WorldLocation) / MaxDistance, 1.f);

			const FVector DirToPosition = (LockedStreamPosition.WorldLocation - BoatLocation).GetSafeNormal();
			const FVector DirToInFront = LockedStreamPosition.WorldOrientation.ForwardVector;
			const float Angle = DirToPosition.DotProduct(DirToInFront);

			LockedDistanceMultiplier += 1.f;
			LockedDistanceMultiplier *= 0.5f;

			if(Angle >= -0.5f)
			{
				LockedDistanceMultiplier *= FMath::Lerp(10.f, 2.f, VelocityAlpha);
			}
			else
			{
				LockedDistanceMultiplier *= 0.f;
				bForceNewSpline = true;
			}

			FVector LockedStreamDirection = LockedStreamPosition.WorldRotation.ForwardVector;
			LockedStreamDirection *= LockedDistanceMultiplier;
			WantedStreamDirection += LockedStreamDirection;
			BestScore = LockedDistanceMultiplier;

			//Print("CurrentStream" + LockedStream + " Score: " + LockedDistanceMultiplier);
			//System::DrawDebugLine(LockedStreamPosition.WorldLocation, LockedStreamPosition.WorldLocation + (FVector::UpVector * 3000), LineColor = FLinearColor::Blue, Thickness = 5.f);
		}

		FVector BestLinkedStream;
		float BestLinkedScore = -1;

		FVector LinkedDirections;
		for(int i = 0; i < LockedStream.LinkedStreams.Num(); ++i)
		{
			APirateOceanStreamActor LinkedStream = LockedStream.LinkedStreams[i];

			if(LinkedStream == nullptr)
				continue;
				
			if(LinkedStream.Spline == nullptr)
				continue;

			FHazeSplineSystemPosition LinkedStreamPosition = LinkedStream.Spline.GetPositionClosestToWorldLocation(BoatLocation, true);
			float LinkedDistanceMultiplier = 1 - FMath::Min(BoatLocation.Distance(LinkedStreamPosition.WorldLocation) / MaxDistance, 1.f);

			if(LinkedDistanceMultiplier <= 0)
				continue;

			if(VelocityAlpha < 0.1f && !bForceNewSpline)
				continue;

			FHazeSplineSystemPosition LinkedStreamDirectionPosition = LinkedStream.Spline.GetPositionClosestToWorldLocation(BoatLocation + (Velocity * VelocityAlpha), true);
			FVector DirToPosition = (LinkedStreamDirectionPosition.WorldLocation - BoatLocation).GetSafeNormal();
			DirToPosition = FMath::Lerp(DirToPosition, LinkedStreamPosition.WorldRotation.ForwardVector, 0.7f).GetSafeNormal();
			
			const float DirectionAlpha = DirToPosition.DotProduct(Owner.ActorForwardVector);
			if(DirectionAlpha < 0.8f && !bForceNewSpline)
				continue;

			LinkedStreamDirectionPosition = LinkedStream.Spline.GetPositionClosestToWorldLocation(BoatLocation - (Owner.GetActorForwardVector() * Collision.GetCapsuleHalfHeight()), true);
			DirToPosition = (LinkedStreamDirectionPosition.WorldLocation - BoatLocation).GetSafeNormal();
			const float CanLinkAlpha = 1.f - DirToPosition.DotProduct(Owner.ActorForwardVector);
			if(CanLinkAlpha < 0.8f && !bForceNewSpline)
				continue;
	
			LinkedDistanceMultiplier += 1.f;
			LinkedDistanceMultiplier *= 0.5f;
			LinkedDistanceMultiplier *= FMath::Lerp(0.f, 10.f, FMath::Pow((LinkedDistanceMultiplier + VelocityAlpha + DirectionAlpha) / 3.f, 2.f));

			Streams.Add(LinkedStream);

			if(LinkedDistanceMultiplier > BestLinkedScore)
			{
				BestLinkedScore = LinkedDistanceMultiplier;
				BestLinkedStream = LinkedStreamPosition.WorldRotation.ForwardVector;
				BestLinkedStream *= LinkedDistanceMultiplier;
			}
			
			if(LinkedDistanceMultiplier > BestScore)
			{
				BestScore = LinkedDistanceMultiplier;
				ClosestIndex = Streams.Num() - 1;
			}

			//FVector DebugLocation = LinkedStreamPosition.WorldLocation;
			//System::DrawDebugLine(DebugLocation - (FVector::UpVector * 3000), DebugLocation + (FVector::UpVector * 3000), LineColor = FLinearColor::Red, Thickness = 5.f);
			//Print("Stream " + LinkedStream + " Score: " + LinkedDistanceMultiplier);
		}

		WantedStreamDirection += BestLinkedStream;
		WantedStreamDirection.Normalize();
		StreamDirection = FMath::VInterpConstantTo(StreamDirection, WantedStreamDirection, DeltaTime, 1.5f);
		OutBestStream = Streams[ClosestIndex];

		// FVector DebugLocation = BoatLocation;
		// DebugLocation += FVector(0.f, 0.f, 500.f);
		// System::DrawDebugArrow(DebugLocation, DebugLocation + (StreamDirection * 500.f));
	}

	UFUNCTION(BlueprintCallable)
	void SetStreamSpline(APirateOceanStreamActor NewSpline)
	{
		if(LockedStream == nullptr && NewSpline != nullptr)
			OnWheelBoatEnteredStream.Broadcast();
		else if(LockedStream != nullptr && NewSpline == nullptr)
			OnWheelBoatExitedStream.Broadcast();

		LockedStream = NewSpline;

		if(LockedStream != nullptr)
		{
			FVector BoatLocation = Owner.GetActorLocation();
			FHazeSplineSystemPosition ClosestStreamPosition = LockedStream.Spline.GetPositionClosestToWorldLocation(BoatLocation, true);
			PositionClosestToBoat = ClosestStreamPosition.WorldLocation;
			StreamDirection = ClosestStreamPosition.WorldRotation.ForwardVector;
		}

	}

	float CalculateSidePushWithStream(FVector BoatForward)
	{
		float DotProd = BoatForward.DotProduct(StreamDirection);
		float CosAngle  = FMath::Cos(FMath::Acos(DotProd) * 2);
		float Result = FMath::Square(CosAngle);
		return Result;
	}

	float GetStreamMovementForce()const property
	{
		if(LockedStream == nullptr || LockedStream.Spline == nullptr)
			return 0.f;
		return LockedStream.StreamForce;
	}

	void CheckDirectionToTurn(FVector BoatForward, FVector BoatRight)
	{
		float FwdDotProd = BoatForward.DotProduct(StreamDirection);
		float RightDotProd = BoatRight.DotProduct(StreamDirection);

		bool FacingFwd;
		bool FacingRight;
		
		if(FwdDotProd >= 0)
		{
			FacingFwd = true;
		}
		else
		{
			FwdDotProd *= -1;
			FacingFwd = false;
		}

		if(RightDotProd >= 0)
		{
			FacingRight = false;
		}
		else
		{
			RightDotProd *= -1;
			FacingRight = true;
		}


		if(FwdDotProd > RightDotProd)
		{
			if(!FacingFwd)
			{
				if(FacingRight)
					StreamRotationForce = AdditiveRotationForce;
				else 
					StreamRotationForce = DecrementalRotationForce;
			}
			else
			{	
				if(FacingRight)
					StreamRotationForce = DecrementalRotationForce;
				else 
					StreamRotationForce = AdditiveRotationForce;
			}
		}
		else
		{

			if(!FacingRight)
			{
				if(FacingFwd)
					StreamRotationForce = AdditiveRotationForce;
				else 
					StreamRotationForce = DecrementalRotationForce;
			}
			else
			{	
				if(FacingFwd)
					StreamRotationForce = DecrementalRotationForce;
				else 
					StreamRotationForce = AdditiveRotationForce;
			}
		}
	}
};
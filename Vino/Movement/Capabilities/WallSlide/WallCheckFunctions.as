import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideSettings;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideComponent;

enum EWallslideValidityType
{
	Valid,
	InvalidTag,
	InvalidAngle,
	NoHit,
}

struct FWallSlideChecker
{
	UHazeBaseMovementComponent MoveComp;
	UCharacterWallSlideComponent WallDataComp;
	FCharacterWallSlideSettings Settings;

	bool bDebugActive = false;

	bool IsFrontSolid(const FTransform& RotateToNormalTransform, FHazeHitResult& OutCenterHit) const
	{
		FTransform TraceTransform = RotateToNormalTransform;
		SideAndRotationCheck(TraceTransform);

		float NumberOfSegments = WallDataComp.DynamicSettings.NumberOfCenterTracingSegments;
		float StartHeight = MoveComp.ActorShapeExtents.Z * 1.55f;
		float EndHeight = MoveComp.ActorShapeExtents.Z * 0.25f;
		float SegmentDelta = (EndHeight - StartHeight) / NumberOfSegments;

		FHazeHitResult DummyResult;
		for (float ICenterSegment = 0; ICenterSegment < NumberOfSegments; ICenterSegment++)
		{
		 	FVector HighLocalTraceStart(MoveComp.ActorShapeExtents.X * 0.9f, 0.f, StartHeight + (SegmentDelta * ICenterSegment));
			const bool bIsCenterTrace = ICenterSegment == NumberOfSegments / 2;
			
			if (bIsCenterTrace)
			{
				// We specificy the center check as the trace we return out that will be the data we base the sliding on.
				if (TraceCheckWall(HighLocalTraceStart, TraceTransform, Settings.CenterDistanceCheck, OutCenterHit) != EWallslideValidityType::Valid)
		 			return false;
			}
			else
			{
				if (TraceCheckWall(HighLocalTraceStart, TraceTransform, Settings.CenterDistanceCheck, DummyResult) != EWallslideValidityType::Valid)
		 			return false;
			}
		}

		return true;
	}
	
	bool SideAndRotationCheck(FTransform& InOutRotation) const
	{
		// We only care about hitresult from the center trace.
		FHazeHitResult LeftSideHit;
		FHazeHitResult RightSideHit;

		EWallslideValidityType LeftSideValidity;
		EWallslideValidityType RightSideValidity;

		//Left Check
		FVector LeftLocalHipTraceStart(-10.f, MoveComp.ActorShapeExtents.Y + WallDataComp.DynamicSettings.SidesExtraWidth, MoveComp.ActorShapeExtents.Z);
		LeftSideValidity = TraceCheckWall(LeftLocalHipTraceStart, InOutRotation, WallDataComp.DynamicSettings.SideDistanceCheck, LeftSideHit);
		if (LeftSideValidity == EWallslideValidityType::NoHit)
			return false;

		//Right Check
		FVector RightLocalHipTraceStart(-10.f, -MoveComp.ActorShapeExtents.Y - WallDataComp.DynamicSettings.SidesExtraWidth, MoveComp.ActorShapeExtents.Z);
		RightSideValidity = TraceCheckWall(RightLocalHipTraceStart, InOutRotation, WallDataComp.DynamicSettings.SideDistanceCheck, RightSideHit);
		if (RightSideValidity == EWallslideValidityType::NoHit)
			return false;

		if (LeftSideValidity != EWallslideValidityType::Valid && RightSideValidity != EWallslideValidityType::Valid)
			return false;
		else if (LeftSideValidity == RightSideValidity)
			return true;

		FHazeHitResult ValidHit = LeftSideHit;
		if (RightSideValidity == EWallslideValidityType::Valid)
			ValidHit = RightSideHit;

		bool bOutput = true;
		InOutRotation.SetRotation(Math::MakeQuatFromXZ(-ValidHit.Normal, InOutRotation.Rotation.UpVector));
		if (TraceCheckWall(LeftLocalHipTraceStart, InOutRotation, WallDataComp.DynamicSettings.SideDistanceCheck, LeftSideHit) != EWallslideValidityType::Valid)
			bOutput = false;

		if (TraceCheckWall(RightLocalHipTraceStart, InOutRotation, WallDataComp.DynamicSettings.SideDistanceCheck, RightSideHit) != EWallslideValidityType::Valid)
			bOutput = false;

		return bOutput;
	}

	EWallslideValidityType TraceCheckWall(const FVector& LocalPosition, const FTransform& RotateToNormalTransform, const float LengthToTrace, FHazeHitResult& OutHit) const
	{
		const FVector LineStart = RotateToNormalTransform.TransformPosition(LocalPosition);
		const FVector LineEnd = LineStart + RotateToNormalTransform.GetRotation().Vector() * LengthToTrace;
		const float DebugDrawTime = bDebugActive ? 0.f : -1.f;

		if (MoveComp.LineTrace(LineStart, LineEnd, OutHit, DebugDrawTime))
		{
			if (!OutHit.Component.HasTag(ComponentTags::WallSlideable))
				return EWallslideValidityType::InvalidTag;

			// Verify the surface isn't to tilted.
			float WallToUpDegrees = Math::DotToDegrees(OutHit.ImpactNormal.DotProduct(MoveComp.WorldUp));
			if (FMath::Abs(WallToUpDegrees - 90.f) > Settings.MaxWallslideAngle)
				return EWallslideValidityType::InvalidAngle;

			return EWallslideValidityType::Valid;
		}

		return EWallslideValidityType::NoHit;
	}
}


import Peanuts.Movement.CollisionData;
import Rice.TemporalLog.TemporalLogComponent;

struct FMovementFrameInput
{
	UHazeCollisionSolver Solver;
	FCollisionSolverActorState ActorState;
	FCollisionMoveQuery Query;
}

struct FVisualData
{	
	FVector Location = FVector::ZeroVector;
	FVector ExtraData = FVector::ZeroVector;
	FRotator Rotation = FRotator::ZeroRotator;
	float Thickness = 1.f;
	bool bAlwaysDraw = false;
	bool bAddAsText = true;
	FLinearColor Color = FLinearColor::White;
};

enum EMovementVisualizationType
{
	Line,
	Capsule,
	Box,
	Sphere,
	Message,
}

struct FEventData
{
	EMovementVisualizationType Type;

	FString StringValue;
	FVisualData VisualData;
};

struct FNamedEvents
{
	TArray<FEventData> Events;
};

struct FDebugFrameData
{
	TMap<UHazeCollisionSolver, FMovementFrameInput> Data;
};

class UMovementDebugDataComponent : UActorComponent
{
	int LastFrameAmountOfIterations = 0;

	UHazeBaseMovementComponent MoveComp = nullptr;
	FCollisionShape CollisionShape;

	FCollisionSolverActorState ActorState;
	FCollisionMoveQuery Query;

	FVector CollisionOffset = FVector::ZeroVector;

	int EventCounter = 0;
	uint CurrentFrame = 0;
	int MoveWithCounter = 0;
	int DepentrationCounter = 0.f;

	int ErrorCounter = 0;

	TMap<FName, FNamedEvents> EventData;
	TMap<int, FDebugFrameData> DebugFrameData;

	TArray<int> IterationCounts;
	default IterationCounts.SetNumZeroed(10);

	bool LastTemporalLogActive = false;

	void SetFrameIterationCount(int IterationCount)
	{
		if (!ensure(IterationCount > 0))
			return;

		if (!ensure(IterationCount < 11))
			return;

		LastFrameAmountOfIterations = IterationCount;
		IterationCounts[IterationCount - 1] += 1;
	}

	void RerunFrame(int FrameNumber)
	{
		FDebugFrameData FrameInput;
		if (!DebugFrameData.Find(FrameNumber, FrameInput))
		{
			return;
		}

		for(auto FrameInputPair : FrameInput.Data)
		{
			UHazeCollisionSolver Solver = FrameInputPair.Key;
			if (Solver != nullptr)
			{
				Solver.OverrideActorState(FrameInputPair.Value.ActorState);
				Solver.CollisionCheckDelta(FrameInputPair.Value.Query);
			}
		}
	}

	void FrameReset(FCollisionSolverActorState InActorState, FCollisionMoveQuery InQuery, FVector InCollisionOffset, const UHazeCollisionSolver InSolver)
	{
		if (CurrentFrame != GFrameNumber)
		{
			EventCounter = 0;
			MoveWithCounter = 0;
			ErrorCounter = 0;
			DepentrationCounter = 0;
			EventData.Reset();
		}

		CurrentFrame = GFrameNumber;

		ActorState = InActorState;
		Query = InQuery;
		CollisionOffset = InCollisionOffset;

		if (MoveComp == nullptr)
			MoveComp = UHazeBaseMovementComponent::Get(Owner);
		
		CollisionShape = MoveComp.CollisionShape;

		// If we are temporal logging, we want to also internally log frames so we can re-run them later
		auto LogComponent = UTemporalLogComponent::Get(Owner);
		if (LogComponent != nullptr)
		{
			UHazeCollisionSolver Solver = InSolver.AsMutable();
			if (LogComponent.bEnabled)
			{
				// If we weren't logging last frame, clear all stored data
				if (!LastTemporalLogActive)
				{
					DebugFrameData.Empty();
				}

				UHazeCollisionSolver MutableSolver = Cast<UHazeCollisionSolver>(Solver);

				FDebugFrameData& FrameInputData = DebugFrameData.FindOrAdd(GFrameNumber); 
				FMovementFrameInput& FrameInput = FrameInputData.Data.FindOrAdd(MutableSolver);

				FrameInput.Solver = Solver;
				FrameInput.ActorState = InActorState;
				FrameInput.Query = InQuery;
			}

			LastTemporalLogActive = LogComponent.bEnabled;
		}
	}

	void LogString(FName EventName, FString Value)
	{
		FEventData Data;
		Data.Type = EMovementVisualizationType::Message;
		
		Data.StringValue = Value;
		

		EventData.FindOrAdd(EventName).Events.Add(Data);
	}

	void LogLine(FName EventName, FVector Start, FVector End, FLinearColor Color, float Thickness = 1.f, bool bAddAsText = false)
	{
		FEventData Data;
		Data.Type = EMovementVisualizationType::Line;

		Data.VisualData.Location = Start;
		Data.VisualData.ExtraData = End;
		Data.VisualData.Color = Color;
		Data.VisualData.Thickness = Thickness;
		Data.VisualData.bAddAsText = bAddAsText;
		
		EventData.FindOrAdd(EventName).Events.Add(Data);
	}

	void LogShapeCenterLine(FName EventName, FVector Start, FVector End, FLinearColor Color, float Thickness = 1.f)
	{
		LogLine(EventName, Start + CollisionOffset, End + CollisionOffset, Color, Thickness);
	}

	void LogSphere(FName EventName, FVector Location, float SphereRadius, FLinearColor Color, float Thickness = 1.f)
	{
		FEventData Data;
		Data.Type = EMovementVisualizationType::Sphere;

		Data.VisualData.Location = Location;
		Data.VisualData.ExtraData = FVector(SphereRadius, 0.f, 0.f);
		Data.VisualData.Color = Color;
		Data.VisualData.Thickness = Thickness;
		
		EventData.FindOrAdd(EventName).Events.Add(Data);
	}

	void LogCapsule(FName EventName, FVector Location, FRotator Rotation, float CapsuleRadius, float CapsuleHalfHeight, FLinearColor Color, float Thickness = 1.f)
	{
		FEventData Data;
		Data.Type = EMovementVisualizationType::Capsule;

		Data.VisualData.Location = Location;
		Data.VisualData.ExtraData = FVector(CapsuleRadius, 0.f, CapsuleHalfHeight);
		Data.VisualData.Color = Color;
		Data.VisualData.Thickness = Thickness;
		Data.VisualData.Rotation = Rotation;
		
		EventData.FindOrAdd(EventName).Events.Add(Data);
	}

	void LogBox(FName EventName, FVector Location, FRotator Rotation, FVector BoxExtents, FLinearColor Color, float Thickness = 1.f)
	{
		FEventData Data;
		Data.Type = EMovementVisualizationType::Box;

		Data.VisualData.Location = Location;
		Data.VisualData.ExtraData = BoxExtents;
		Data.VisualData.Color = Color;
		Data.VisualData.Thickness = Thickness;
		Data.VisualData.Rotation = Rotation;
		
		EventData.FindOrAdd(EventName).Events.Add(Data);
	}

	void LogCharacterCollisionShape(FName EventName, FVector Location, FLinearColor Color, bool bActorOrigin = true, float Thickness = 1.f)
	{
		FVector Offset = bActorOrigin ? CollisionOffset : FVector::ZeroVector;
		LogCollisionShape(EventName, CollisionShape, Location + Offset, ActorState.Rotation.Rotator(), Color, Thickness);
	}

	void LogCollisionShape(FName EventName, FCollisionShape Shape, FVector Location, FRotator Rotation, FLinearColor Color, float Thickness = 1.f)
	{
		switch (Shape.ShapeType)
		{
			case ECollisionShape::Capsule:
				LogCapsule(EventName, Location, Rotation, Shape.CapsuleRadius, Shape.CapsuleHalfHeight, Color, Thickness);
			break;
			case ECollisionShape::Sphere:
				LogSphere(EventName, Location, Shape.SphereRadius, Color, Thickness);
			break;
			case ECollisionShape::Box:
				LogBox(EventName, Location, Rotation, Shape.Box, Color, Thickness);
			break;
			default:
				//waht
			break;
		}
	}

	void LogStartState(FCollisionSolverActorState ActorState, FCollisionMoveQuery MoveQuery)
	{
		FLinearColor ShapeColor = ActorState.PhysicsState.GroundedState == EHazeGroundedState::Grounded ? FLinearColor::Green : FLinearColor::Blue;
		LogString(n"Instigator", ActorState.InstigatorName.ToString());
		LogCharacterCollisionShape(n"Start", MoveQuery.Location, ShapeColor, true, 1.f);
		LogLine(n"Start", MoveQuery.Location, MoveQuery.Location + MoveQuery.Velocity, FLinearColor::Yellow);
		LogString(n"StartVelocity", "" + MoveQuery.Velocity.Size());
	}

	void LogStandStill(FCollisionMoveQuery MoveQuery, FCollisionSolverOutput Output)
	{
		FLinearColor ShapeColor = Output.PhysicsState.GroundedState == EHazeGroundedState::Grounded ? FLinearColor::Green : FLinearColor::Blue;
		LogCharacterCollisionShape(n"End", MoveQuery.Location, ShapeColor, true, 1.f);
		LogString(n"EndVelocity", "" + 0.f);

		LogString(n"GroundedState", "" + Output.PhysicsState.GroundedState);
		
		LogString(n"StandStill", "StandStillFrame");

		SetFrameIterationCount(1);
	}

	void LogEndState(FCollisionSolverState SolverState, FCollisionSolverOutput Output, int IterationCount)
	{
		FLinearColor ShapeColor = Output.PhysicsState.GroundedState == EHazeGroundedState::Grounded ? FLinearColor::Green : FLinearColor::Blue;
		LogCharacterCollisionShape(n"End", SolverState.CurrentLocation, ShapeColor, true, 1.f);
		LogLine(n"End", SolverState.CurrentLocation, SolverState.CurrentLocation + SolverState.CurrentVelocity, FLinearColor::Yellow);
		LogString(n"EndVelocity", "" + SolverState.CurrentVelocity.Size());
		

		LogString(n"GroundedState", "" + SolverState.PhysicsState.GroundedState);
		if (SolverState.PhysicsState.Impacts.DownImpact.bBlockingHit && SolverState.PhysicsState.Impacts.DownImpact.Actor != nullptr)
			LogString(n"Down Impact", "" + SolverState.PhysicsState.Impacts.DownImpact.Actor.Name);
		if (SolverState.PhysicsState.Impacts.ForwardImpact.bBlockingHit && SolverState.PhysicsState.Impacts.ForwardImpact.Actor != nullptr)
			LogString(n"Forward Impact", "" + SolverState.PhysicsState.Impacts.ForwardImpact.Actor.Name);

		SetFrameIterationCount(IterationCount);
	}

	void LogStartMoveWith(FCollisionSolverActorState ActorState, FCollisionMoveQuery MoveQuery)
	{
		FName MoveWithName("MoveWithStart" + MoveWithCounter);

		FLinearColor ShapeColor = ActorState.PhysicsState.GroundedState == EHazeGroundedState::Grounded ? FLinearColor::Green : FLinearColor::Blue;
		LogCharacterCollisionShape(MoveWithName, MoveQuery.Location, ShapeColor, true, 1.f);
		LogLine(MoveWithName, MoveQuery.Location, MoveQuery.Location + MoveQuery.Delta, FLinearColor::Yellow);
		LogString(n"MoveWithDelta", "" + MoveQuery.Delta.Size());
	}

	void LogEndMoveWith(FCollisionSolverActorState ActorState, FCollisionMoveQuery MoveQuery, FVector MovedDelta)
	{
		FName MoveWithName("MoveWithEnd" + MoveWithCounter);

		LogCharacterCollisionShape(MoveWithName, MoveQuery.Location + MovedDelta, FLinearColor::LucBlue, true, 1.f);
		LogLine(MoveWithName, MoveQuery.Location, MoveQuery.Location + MoveQuery.Delta, FLinearColor::Yellow);
		LogLine(MoveWithName, MoveQuery.Location, MoveQuery.Location + MovedDelta, FLinearColor::Teal);
		LogString(n"MoveWithWantedDelta", "" + MoveQuery.Delta.Size());
		LogString(n"MoveWithMovedDelta", "" + MovedDelta.Size());
		MoveWithCounter++;
	}

	void LogMoveWithRedirect(FVector StartLocation, FCollisionSolverState SolverState, FVector SweepDelta, FVector FullDelta, float SideMovementLeft, FHitResult Hit)
	{
		FName EventName = FName("MoveWithRedirect" + MoveWithCounter);

		LogCharacterCollisionShape(EventName, SolverState.CurrentLocation, FLinearColor::LucBlue, true, 1.f);
		LogCharacterCollisionShape(EventName, Hit.Location, FLinearColor::Teal, false, 0.01f);
		LogLine(EventName, StartLocation, SolverState.CurrentLocation + FullDelta, FLinearColor::DPink, 0.1f);
		LogLine(EventName, SolverState.CurrentLocation, SolverState.CurrentLocation + SweepDelta, FLinearColor::Red);
		LogLine(EventName, SolverState.CurrentLocation, SolverState.CurrentLocation + SolverState.RemainingDelta, FLinearColor::Green);
		LogLine(EventName, SolverState.CurrentLocation, SolverState.CurrentLocation + SolverState.RemainingDelta.GetSafeNormal() * 200.f, FLinearColor::Teal, 0.1f);

		LogHitResult(EventName, Hit);
	}

	void LogIterationBegin(int IterationCount)
	{
		EventCounter = IterationCount;
		FName IterationName = FName("Begin Iteration: " + EventCounter);

		LogString(IterationName, "--- Iteration: " + EventCounter + " ---");
	}

	void LogMoveWithStepDown(FCollisionSolverState SolverState, FVector TraceStart, FVector TraceEnd, FHitResult Hit)
	{
		FName EventName = FName("MoveWithStepDown" + MoveWithCounter);

		LogCharacterCollisionShape(EventName, SolverState.CurrentLocation, FLinearColor::Green, true, 0.1f);
		LogCharacterCollisionShape(EventName, TraceStart, FLinearColor::LucBlue, true, 0.1f);
		LogCharacterCollisionShape(EventName, TraceEnd, FLinearColor::LucBlue, true, 0.1f);
		LogLine(EventName, TraceStart, TraceEnd, FLinearColor::LucBlue);

		LogHitResult(EventName, Hit);
	}

	void LogCollisionSweep(FVector Start, FVector End, FHitResult Hit)
	{
		{
			FName EventName = FName("CollisionSweep" + EventCounter);

			if (Hit.bBlockingHit)
			{
				LogSphere(EventName, Start, 2.f, FLinearColor::Red, 1.f);
				LogCharacterCollisionShape(EventName, Hit.Location, FLinearColor::Red, false, 0.1f);
				LogLine(EventName, Start, Hit.Location - CollisionOffset, FLinearColor::Red);
				LogLine(EventName, Hit.Location - CollisionOffset, End, FLinearColor::White);
			}
			else
			{
				LogSphere(EventName, Start, 2.f, FLinearColor::White, 1.f);
				LogLine(EventName, Start, End, FLinearColor::White);
				LogCharacterCollisionShape(EventName, End, FLinearColor::Green, true, 0.1f);
			}
		}

		if (Hit.bBlockingHit)
		{
			FName EventName = FName("SweepImpact" + EventCounter);

			LogCharacterCollisionShape(EventName, Hit.Location, FLinearColor::Red, false, 0.1f);

			LogSphere(EventName, Hit.ImpactPoint, 1.5f, FLinearColor::Red, 1.f);

			LogHitResult(EventName, Hit);
		}
	}

	void LogHitResult(FName EventName, FHitResult Hit)
	{
		LogLine(EventName, Hit.ImpactPoint, Hit.ImpactPoint + Hit.ImpactNormal * 50.f, FLinearColor::DPink, 0.5f);
		LogLine(EventName, Hit.ImpactPoint, Hit.ImpactPoint + Hit.Normal * 25.f, FLinearColor::Red, 1.2f);
	}

	void LogRedirect(FCollisionRedirectInput Input, FVector PrevDelta, FVector NewDelta)
	{
		FName EventName = FName("Redirect" + EventCounter);
		FVector RootLocation = Input.Impact.ActorLocation;

		LogCharacterCollisionShape(EventName, RootLocation, FLinearColor::White, true, 0.1f);
		LogLine(EventName, RootLocation - PrevDelta, RootLocation, FLinearColor::Red);
		LogLine(EventName, RootLocation, RootLocation + NewDelta, FLinearColor::Green);

		LogSphere(EventName, Input.Impact.ImpactPoint, 2.f, FLinearColor::Red, 1.f);
		LogLine(EventName, Input.Impact.ImpactPoint, Input.Impact.ImpactPoint + Input.RedirectNormal * 50.f, FLinearColor::DPink);
	}

	void LogStepUpSurfaceCheck(FHitResult WallImpact, FVector LineFrom, FVector LineTo, FHitResult LineHit, bool bHeightIsValid, bool bSurfaceIsValid)
	{
		FName EventName = FName("LogStepUpSurfaceCheck" + EventCounter);

		LogHitResult(EventName, WallImpact);
		LogCharacterCollisionShape(EventName, WallImpact.Location, FLinearColor::Gray, false);
		
		if (LineHit.bStartPenetrating)
		{
			LogSphere(EventName, LineFrom, 2.f, FLinearColor::Red, 1.f);
		}
		else if (!LineHit.bBlockingHit)
		{
			LogSphere(EventName, LineFrom, 2.f, FLinearColor::Gray, 1.f);
			LogLine(EventName, LineFrom, LineTo, FLinearColor::Gray);
		}
		else
		{
			LogSphere(EventName, LineFrom, 2.f, FLinearColor::White, 1.f);

			if (!bSurfaceIsValid)
			{
				LogLine(EventName, LineFrom, LineHit.ImpactPoint, FLinearColor::Red);
				LogLine(EventName, LineHit.ImpactPoint, LineTo, FLinearColor::Gray);
				LogSphere(EventName, LineHit.ImpactPoint, 2.f, FLinearColor::Red, 1.f);
			}
			else
			{
				LogLine(EventName, LineFrom, LineHit.ImpactPoint, FLinearColor::Green);
				LogLine(EventName, LineHit.ImpactPoint, LineTo, FLinearColor::Gray);
				LogSphere(EventName, LineHit.ImpactPoint, 2.f, FLinearColor::Green, 1.f);
			}

		}

	}

	void LogGroundedCheck(FVector ActorLocation, FHitResult GroundImpact, FHitResult LineHit, bool bEdgeIsValid, bool bIsGrounded)
	{
		FName EventName = FName("GroundedCheck" + EventCounter);

		if (!GroundImpact.bBlockingHit)
		{
			LogCharacterCollisionShape(EventName, ActorLocation, FLinearColor::Blue);
			return;
		}

		if (LineHit.bBlockingHit || !bEdgeIsValid)
		{
			LogLine(EventName, LineHit.TraceStart, LineHit.TraceEnd, FLinearColor::Purple);
		}

		FLinearColor DebugColor = bIsGrounded ? FLinearColor::Green : FLinearColor::Red;
		if (!bEdgeIsValid)
			DebugColor = FLinearColor::Yellow;

		FVector EdgeDelta = (GroundImpact.Location - GroundImpact.ImpactPoint).ConstrainToPlane(MoveComp.WorldUp);

		FVector ActorCenterAtImpactHeight = GroundImpact.ImpactPoint + EdgeDelta;
		LogLine(EventName, GroundImpact.ImpactPoint, ActorCenterAtImpactHeight, FLinearColor::LucBlue);

		LogLine(EventName, ActorCenterAtImpactHeight, ActorLocation, FLinearColor::LucBlue);

		LogCharacterCollisionShape(EventName, GroundImpact.Location, DebugColor, false);
	}

	void LogEdgeCheckStartData(FVector CurrentLocation, FVector HitHorizontalDelta, FHazeHitResult Hit)
	{
		FName EventName = FName("EdgeCheckStartData" + EventCounter);

		LogHitResult(EventName, Hit.FHitResult);
		LogCharacterCollisionShape(EventName, CurrentLocation, FLinearColor::White);
		LogCharacterCollisionShape(EventName, CurrentLocation + HitHorizontalDelta, FLinearColor::LucBlue);
		LogLine(EventName, CurrentLocation, Hit.ImpactPoint, FLinearColor::Blue);
	}

	void LogEdgeCheck(bool bLineGrounded, bool bShapeGrounded, FMovementQueryLineParams LineParams, FMovementQueryParams ShapeParams, FHazeHitResult Hit)
	{
		FName EventName = FName("EdgeCheck" + EventCounter);

		LogCharacterCollisionShape(EventName, LineParams.From, FLinearColor::White);

		FLinearColor LineColor = bLineGrounded ? FLinearColor::Green : FLinearColor::Red;
		LogLine(EventName, LineParams.From, LineParams.To, LineColor);

		if (bLineGrounded)
			return;
		
		if (!Hit.bBlockingHit)
		{
			LogCharacterCollisionShape(EventName, ShapeParams.From, FLinearColor::White);
			LogCharacterCollisionShape(EventName, ShapeParams.To, FLinearColor::White);
			LogLine(EventName, ShapeParams.From, ShapeParams.To, FLinearColor::White);
			return;
		}

		if (Hit.bStartPenetrating)
		{
			LogCharacterCollisionShape(EventName, ShapeParams.From, FLinearColor::Red);
			LogLine(EventName, ShapeParams.From, ShapeParams.To, FLinearColor::Red);
			return;
		}

		FLinearColor ShapeColor = bShapeGrounded ? FLinearColor::Green : FLinearColor::Red;
		LogCharacterCollisionShape(EventName, ShapeParams.From, FLinearColor::White);
		LogCharacterCollisionShape(EventName, ShapeParams.To, ShapeColor);
		LogLine(EventName, ShapeParams.From, ShapeParams.To, ShapeColor);
		LogHitResult(EventName, Hit.FHitResult);
	}

	void LogStepUp(FVector StartLocation, FVector EndLocation, FVector StepUpVector, bool bDidStepUp, FHitResult DownTrace)
	{
		FName EventName = FName("StepUp" + EventCounter);

		const FVector StepUpLocation = StartLocation + StepUpVector;
		LogLine(EventName, StartLocation, StepUpLocation, FLinearColor::Blue);

		const FVector ForwardDelta = (EndLocation - StartLocation).ConstrainToPlane(ActorState.WorldUp);
		LogLine(EventName, StepUpLocation, StepUpLocation + ForwardDelta, FLinearColor::Yellow);

		LogCharacterCollisionShape(EventName, StartLocation, FLinearColor::Gray);

		if (bDidStepUp)
		{
			LogCharacterCollisionShape(EventName, EndLocation, FLinearColor::Green);

			LogHitResult(EventName, DownTrace);
		}
		else
		{	
			LogCharacterCollisionShape(EventName, EndLocation, FLinearColor::Red);

			if (DownTrace.bBlockingHit)
				LogHitResult(EventName, DownTrace);
		}
	}

	void LogStepDown(FVector StartLocation, FVector EndLocation, FVector StepDownVector, bool bEndedGrounded, FHitResult LineCheck, FHitResult ShapeHit)
	{
		FName EventName = FName("StepDown" + EventCounter);

		LogCharacterCollisionShape(EventName, StartLocation, FLinearColor::Gray);

		const FVector StepDownLocation = StartLocation - StepDownVector;
		LogLine(EventName, StartLocation, StepDownLocation, FLinearColor::Blue);

		if (ShapeHit.bBlockingHit)
		{
			LogHitResult(EventName, ShapeHit);

			if (LineCheck.bBlockingHit) 
				LogLine(EventName, LineCheck.TraceStart, LineCheck.TraceEnd, FLinearColor::Green);
			else
				LogLine(EventName, LineCheck.TraceStart, LineCheck.TraceEnd, FLinearColor::Red);
		}

		if (bEndedGrounded)
			LogCharacterCollisionShape(EventName, EndLocation, FLinearColor::Green);
		else
			LogCharacterCollisionShape(EventName, EndLocation, FLinearColor::Red);
	}

	void LogDepenetrate(FHitResult Hit, FDepenetrationOutput Depen)
	{
		FName EventName = FName("StartPenetrating" + EventCounter);
		LogCharacterCollisionShape(EventName, Hit.Location, FLinearColor::Red, false, 1.f);

		LogLine(EventName, Hit.Location, Hit.Location + Depen.DepenetrationDelta, FLinearColor::Purple);
		LogCharacterCollisionShape(EventName, Hit.Location + Depen.DepenetrationDelta, FLinearColor::Teal, false, 1.f);
		DepentrationCounter++;
	}

	void LogFailedMTDDepenetration(UPrimitiveComponent PrimitiveToDepen, FCollisionShape Shape, FVector ShapeLocation, FRotator ShapeRotation)
	{
		FName EventName = FName("MTDError" + EventCounter + ":" + ErrorCounter++);

		LogBox(EventName, PrimitiveToDepen.WorldLocation, PrimitiveToDepen.WorldRotation, PrimitiveToDepen.BoundingBoxExtents, FLinearColor::Blue);
		LogCollisionShape(EventName, Shape, ShapeLocation, ShapeRotation, FLinearColor::Teal);
	}

	void LogSplineLockDepentrate(FCollisionSolverState SolverState, FHitResult Hit, FVector MTDDir, FHazeSplineSystemPosition SplinePos)
	{
		FName EventName = FName("SplineLockDepenetrating: " + EventCounter);

		LogCharacterCollisionShape(EventName, SolverState.CurrentLocation, FLinearColor::Green, true, 1.f);
		LogCharacterCollisionShape(EventName, Hit.Location, FLinearColor::Red, false, 1.f);

		FVector LineStart = SolverState.CurrentLocation;
		FVector Delta = MTDDir * 750.f;
		LogLine(EventName, LineStart, LineStart + Delta, FLinearColor::Red, 1.f, false);

		LogSplineRange(EventName, SolverState.CurrentLocation, SplinePos, 1500.f, 40, FLinearColor::Purple);
	}

	void LogSplineLockIterationStart(FCollisionSolverState SolverState, FCollisionSolverActorState ActorState, FVector StartDelta, FHazeSplineSystemPosition Current, FHazeSplineSystemPosition Goal)
	{
		FName EventName = FName("LogSplineLockStart: " + EventCounter);

		LogCharacterCollisionShape(EventName, SolverState.CurrentLocation, FLinearColor::Green, true, 1.f);
		FVector Delta = Goal.WorldLocation - Current.WorldLocation;
		LogCharacterCollisionShape(EventName, SolverState.CurrentLocation + Delta, FLinearColor::Blue, true, 1.f);
		FVector LineStart = SolverState.CurrentLocation + ActorState.WorldUp * 10.f;
		LogLine(EventName, LineStart, LineStart + Delta, FLinearColor::Blue, 1.f, false);

		LogSplineLockPositionDif(SolverState, ActorState, Current, Goal);

		FVector DeltaStartPos = SolverState.CurrentLocation + ActorState.Rotation.ForwardVector * 10.f;
		LogLine(EventName, DeltaStartPos, DeltaStartPos + StartDelta, FLinearColor::Green, 1.f, false);
		DeltaStartPos += ActorState.WorldUp * 10.f;
		LogLine(EventName, DeltaStartPos, DeltaStartPos + SolverState.RemainingDelta, FLinearColor::LucBlue, 1.f, false);

		LogSplineRange(EventName, SolverState.CurrentLocation, Current, 1500.f, 40, FLinearColor::LucBlue);
		FVector CharacterLocOnLine = SolverState.CurrentLocation;
		CharacterLocOnLine.Z = Current.WorldLocation.Z;

		LogSphere(EventName, CharacterLocOnLine, 15.f, FLinearColor::Green, 1.f);
		LogSphere(EventName, Current.WorldLocation, 15.f, FLinearColor::LucBlue, 1.f);
		LogSphere(EventName, Goal.WorldLocation, 15.f, FLinearColor::Blue, 1.f);
	}

	void LogSplineLockPositionDif(FCollisionSolverState SolverState, FCollisionSolverActorState ActorState, FHazeSplineSystemPosition First, FHazeSplineSystemPosition Second)
	{
		FName EventName = FName("LogSplineLockPositionDif: " + EventCounter);

		{
			FVector LineStart = (SolverState.CurrentLocation + ActorState.WorldUp * 10.f);
			FVector Delta = Second.WorldLocation - SolverState.CurrentLocation;
			LogLine(EventName, LineStart, LineStart + Delta, FLinearColor::Red, 1.f, false);
			LineStart += ActorState.WorldUp * 10.f;
			Delta = (Second.WorldLocation - SolverState.CurrentLocation).ConstrainToPlane(ActorState.WorldUp);
			LogLine(EventName, LineStart, LineStart + Delta, FLinearColor::LucBlue, 1.f, false);
		}

		{
			LogCharacterCollisionShape(EventName, SolverState.CurrentLocation, FLinearColor::Green, true, 1.f);
			FVector Delta = Second.WorldLocation - First.WorldLocation;
			LogCharacterCollisionShape(EventName, SolverState.CurrentLocation + Delta, FLinearColor::Blue, true, 1.f);
			FVector LineStart = SolverState.CurrentLocation + ActorState.WorldUp * 30.f;
			LogLine(EventName, LineStart, LineStart + Delta, FLinearColor::Blue, 1.f, false);
		}
	}

	void LogSplineLockIterationEnd(FCollisionSolverState SolverState, FCollisionSolverActorState ActorState, FHazeSplineSystemPosition Previous, FHazeSplineSystemPosition Current)
	{
		FName EventName = FName("LogSplineLockEnd: " + EventCounter);

		LogCharacterCollisionShape(EventName, SolverState.CurrentLocation, FLinearColor::Green, true, 1.f);
		FVector Delta = Previous.WorldLocation - Current.WorldLocation;
		LogCharacterCollisionShape(EventName, SolverState.CurrentLocation + Delta, FLinearColor::Gray, true, 1.f);
		FVector LineStart = SolverState.CurrentLocation + ActorState.WorldUp * 10.f;
		LogLine(EventName, LineStart, LineStart + Delta, FLinearColor::Gray, 1.f, false);

		LogSplineRange(EventName, SolverState.CurrentLocation, Current, 1500.f, 40, FLinearColor::LucBlue);
		LogSphere(EventName, Current.WorldLocation, 15.f, FLinearColor::Green, 1.f);
		LogSphere(EventName, Previous.WorldLocation, 15.f, FLinearColor::Gray, 1.f);
	}

	void LogSplineRange(FName EventName, FVector WorldLocation, FHazeSplineSystemPosition SplinePos, float SplineRangeToShow, int StepAmount, FLinearColor Color = FLinearColor::White)
	{
		const UHazeSplineComponentBase Spline = SplinePos.Spline;
		float HalfRange = SplineRangeToShow / 2.f;

		float StartPos = FMath::Max(SplinePos.DistanceAlongSpline - HalfRange, 0.f);
		float EndPos = FMath::Min(SplinePos.DistanceAlongSpline + HalfRange, Spline.SplineLength);

		FVector AnchorPoint = Spline.GetLocationAtDistanceAlongSpline(SplinePos.DistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector ToPlayerDiff = (WorldLocation - AnchorPoint);

		float Range = EndPos - StartPos;
		float ItDelta = Range / float(StepAmount);

		float CurrentPos = StartPos;
		for (int iStep = 0; iStep < StepAmount; ++iStep)
		{
			FVector StartDraw = Spline.GetLocationAtDistanceAlongSpline(CurrentPos, ESplineCoordinateSpace::World) + ToPlayerDiff;
			CurrentPos += ItDelta;
			FVector EndDraw = Spline.GetLocationAtDistanceAlongSpline(CurrentPos, ESplineCoordinateSpace::World) + ToPlayerDiff;

			LogLine(EventName, StartDraw, EndDraw, Color, 1.f, false);
		}
	}

};

// Structure containing positions and tangents for a trajectory
struct FTrajectoryPoints
{
	UPROPERTY()
	TArray<FVector> Positions;
	UPROPERTY()
	TArray<FVector> Tangents;

	int Num()
	{
		return Positions.Num();
	}
}

// This function takes some variables describing a projectile
// and returns its height at time X
// Helper function only used in this file
float TrajectoryFunction(float X, float G, float V)
{
	/*
	Formula for the projectile is:
	-G/2 * (X - V/G) + V^2/2G
	Where X is the time
	G is the gravity/s
	V is the initial vertical velocity
	*/

	float Exp = (X - V / G);
	return -(0.5f * G) * Exp * Exp + ((V * V) / (2.f * G));
}

// This function takes some variables describing a projectile
// and returns its height at time X, but also takes into account the
//		objects' terminal speed (for example player max fall-speed)
// Helper function only used in this file
float TrajectoryFunctionWithTerminalSpeed(float X, float G, float V, float TerminalSpeed)
{
	float TimeToReachTerminal = -((-TerminalSpeed) - V);
	TimeToReachTerminal = TimeToReachTerminal / G;

	if (X > TimeToReachTerminal)
	{
		float HeightAtTerminal = TrajectoryFunction(TimeToReachTerminal, G, V);
		return HeightAtTerminal - TerminalSpeed * (X - TimeToReachTerminal);
	}
	
	return TrajectoryFunction(X, G, V);
}

// Helper function only used in this file
void SplitVectorIntoVerticalHorizontal(FVector Vec, FVector UpVector, FVector& VerticalDirection, float& VerticalLength, FVector& HorizontalDirection, float& HorizontalLength)
{
	//Math::DecomposeVector(VerticalDirection, HorizontalDirection, Vec, UpVector);
	VerticalLength = Vec.DotProduct(UpVector);
	VerticalDirection = UpVector;

	HorizontalDirection = Math::ConstrainVectorToPlane(Vec, UpVector);
	HorizontalLength = HorizontalDirection.Size();
	HorizontalDirection.Normalize();
}

// Calculates the projectile trajectory based on some velocity, gravity etc.
// Returns a collection of points and tangents that approximates the trajectory
// The resolution increases the amount of points (higher resolution = more points)
UFUNCTION(Category = "Trajectory|Calculation")
FTrajectoryPoints CalculateTrajectory(FVector StartLocation, float TrajectoryLength, FVector Velocity, float _GravityMagnitude, float Resolution, float TerminalSpeed = -1.f, FVector WorldUp = FVector::UpVector)
{
	FTrajectoryPoints Result;
	
	// Get horizontal speed and direction
	const float GravityMagnituded = FMath::Abs(_GravityMagnitude);
	float HorizontalSpeed = 0.f;
	FVector HorizontalDirection;
	float VerticalSpeed = 0.f;
	FVector VerticalDirection;
	SplitVectorIntoVerticalHorizontal(Velocity, WorldUp, VerticalDirection, VerticalSpeed, HorizontalDirection, HorizontalSpeed);

	// If speed or distance is zero, just get out
	if (HorizontalSpeed <= 0.f || TrajectoryLength <= 0.f)
	{
		Result.Positions.Add(StartLocation);
		Result.Tangents.Add(Velocity.GetSafeNormal());
		return Result;
	}

	// Total time to fly
	float TotalTime =  TrajectoryLength / ((HorizontalSpeed + FMath::Abs(VerticalSpeed)) * 0.5);

	// Calculate number of steps to take, based on the resolution, horizontal and vertical distance
	int Steps = 1;
	if (Resolution > 0.f)
	{
		float ResolutionLength = 500.f / Resolution;
		Steps = FMath::Abs(FMath::CeilToInt(TrajectoryLength / ResolutionLength)) + FMath::Abs(FMath::CeilToInt(TrajectoryLength / (ResolutionLength * 0.4f)));
	}

	// Maximum steps
	Steps = FMath::Min(Steps, 64);

	TArray<FVector> ResultPoints;

	const float VelocityZ = WorldUp.DotProduct(Velocity);

	for(int i=0; i <= Steps; i++)
	{
		// X is the time
		float X = TotalTime * (float(i) / Steps);

		// Height at time X
		float Eval = 0.f;
		// Tangent at time X (height/s)
		float Tangent = VelocityZ - X * GravityMagnituded;

		if (TerminalSpeed > 0.f)
		{
			Eval = TrajectoryFunctionWithTerminalSpeed(X, GravityMagnituded, VelocityZ, TerminalSpeed);
			Tangent = VelocityZ - X * GravityMagnituded;

			// Limit tangent to terminal speed
			if (Tangent < -TerminalSpeed)
				Tangent = -TerminalSpeed;
		}
		else
		{
			Eval = TrajectoryFunction(X, GravityMagnituded, VelocityZ);
			Tangent = VelocityZ - X * GravityMagnituded;
		}

		FVector TangentVector = HorizontalDirection * HorizontalSpeed + FVector(0.f, 0.f, Tangent);
		TangentVector.Normalize();

		// Add position and tangent
		Result.Positions.Add(StartLocation + FVector(0.f, 0.f, Eval) + HorizontalDirection * HorizontalSpeed * X);
		Result.Tangents.Add(TangentVector);
	}

	return Result;
}

// Calculates the velocity from StartLocation, which hits EndLocation
// The velocity will have a set HorizontalSpeed, the vertical speed will be calculated
//TODO: Make this function return the final length of the trajectory
UFUNCTION(Category = "Trajectory|Calculation")
FVector CalculateVelocityForPathWithHorizontalSpeed(FVector StartLocation, FVector EndLocation, float _GravityMagnitude, float HorizontalSpeed, FVector WorldUp = FVector::UpVector)
{
	if (StartLocation.Equals(EndLocation))
		return FVector::ZeroVector;

	// Get distance and stuff
	const float GravityMagnituded = FMath::Abs(_GravityMagnitude);
	float HorizontalDistance = 0.f;
	float VerticalDistance = 0.f;
	FVector HorizontalDirection;
	FVector VerticalDirection;
	SplitVectorIntoVerticalHorizontal(
		EndLocation - StartLocation,
		WorldUp,
		VerticalDirection,
		VerticalDistance,
		HorizontalDirection,
		HorizontalDistance
	);
	
	// Horizontal flytime
	float FlyTime = HorizontalDistance / HorizontalSpeed;
	/*
	Calculate vertical velocity to achieve given airtime
	(where the curve equals VerticalDifference after FlyTime seconds) 

	Parabola:
	-G/2 * (X - V/G)^2 + V^2/2G = A

	Which gives:
	X = V / G + sqrt((-2A / G) + (V / G)^2)
	V = ((G * X^2) + 2A) / 2X
	*/
	float VerticalVelocity = (VerticalDistance * 2.f + (FlyTime * FlyTime * GravityMagnituded)) / (2.f * FlyTime);

	// Horizontal + Vertical velocity
	return HorizontalDirection * HorizontalSpeed + VerticalDirection * VerticalVelocity;
}

struct FOutCalculateVelocity
{
	FVector Velocity;
	float Time;
	float MaxHeight;
}

// Calculates the projectile velocity from StartLocation, which hits EndLocation
// The projectile will always reach "Height" in its trajectory
// Terminal velocity is the maximum downwards velocity of the path
// 		(for example player fall-speed). It is assumed to be POSITIVE.
//TODO: Make this function return the final length of the trajectory
UFUNCTION(Category = "Projectile|Calculation")
FOutCalculateVelocity CalculateParamsForPathWithHeight(FVector StartLocation, FVector EndLocation, float _GravityMagnitude, float Height, float TerminalSpeed = -1.f, FVector WorldUp = FVector::UpVector)
{
	if (StartLocation.Equals(EndLocation))
		return FOutCalculateVelocity();

	// Get distance and stuff
	const float GravityMagnitude = FMath::Abs(_GravityMagnitude);
	float HorizontalDistance = 0.f;
	float VerticalDistance = 0.f;
	FVector HorizontalDirection;
	FVector VerticalDirection;

	SplitVectorIntoVerticalHorizontal(
		EndLocation - StartLocation,
		WorldUp,
		VerticalDirection,
		VerticalDistance,
		HorizontalDirection,
		HorizontalDistance
	);

	/* Edge cases */
	// Start == End
	if (HorizontalDistance <= 0.f)
		return FOutCalculateVelocity();

	// Height <= 0 (Not possible)
	float _Height = Height;
	if (_Height < 0.f)
		_Height = 0.f;

	// If the vertical distance is greater, it will never reach the target
	// If it's equal, it will reach it at infinite speed
	if (VerticalDistance >= _Height)
		_Height = VerticalDistance + 0.1f;
// 		VerticalDistance = _Height - 0.1f;

	// Calculation to reach certain height 
	// V = sqrt(2HG)
	float Velocity = FMath::Sqrt(2.f * _Height * GravityMagnitude);

/*
	Calculate the airtime of this curve, ending where the curve reaches target height
	(wheTrajectoryve equals VerticalDifference) 

	Parabola:
	-G/2 * (X - V/G)^2 + V^2/2G = A

	(-2A / G) + (V / G)^2
	*/
	float ValueToSqrt = (-2.f * VerticalDistance) / GravityMagnitude +
		((Velocity / GravityMagnitude) * (Velocity / GravityMagnitude));

	// negative values will generate NaNs
	if(ValueToSqrt < 0.f)
		return FOutCalculateVelocity();

	// X = V / G + sqrt((-2A / G) + (V / G)^2)
	float FlyTime = Velocity/GravityMagnitude + FMath::Sqrt(ValueToSqrt);

	if(!FMath::IsFinite(FlyTime))
		return FOutCalculateVelocity();

	// Take terminal velocity into the equation!
	if (TerminalSpeed > 0.f)
	{
		float TimeToReachTerminal = -((-TerminalSpeed) - Velocity);
		TimeToReachTerminal = TimeToReachTerminal / GravityMagnitude;

		// We'll reach terminal before landing!
		if (TimeToReachTerminal < FlyTime)
		{
			// Height on trajectory when terminal is reached
			float TerminalHeight = TrajectoryFunction(TimeToReachTerminal, GravityMagnitude, Velocity);

			float DistanceToFall = TerminalHeight - VerticalDistance;
			float TimeToFall = DistanceToFall / TerminalSpeed;

			FlyTime = TimeToReachTerminal + TimeToFall;
		}
	}
	
	FOutCalculateVelocity Out;
	Out.Velocity = HorizontalDirection * (HorizontalDistance / FlyTime) + (VerticalDirection * Velocity);
	Out.Time = FlyTime;
	Out.MaxHeight = _Height;
	
	// Horizontal speed will be horizontal distance divided by the airtime
	return Out;
}

UFUNCTION(Category = "Projectile|Calculation")
FVector CalculateVelocityForPathWithHeight(FVector StartLocation, FVector EndLocation, float _GravityMagnitude, float Height, float TerminalSpeed = -1.f, FVector WorldUp = FVector::UpVector)
{
	return CalculateParamsForPathWithHeight(StartLocation, EndLocation, _GravityMagnitude, Height, TerminalSpeed, WorldUp).Velocity;
}

// NOT IMPLEMENTED YET
// UFUNCTION(Calculation= "Projectile|Movement")
//FVector CalculateProjectileVelocityForPathWithSpeed(FVector StartLocation, FVector EndLocation, float Gravity, float Speed)
// {
// 	FVector HoriDiff = EndLocation - StartLocation;
// 	HoriDiff.Z = 0.f;

// 	FVector HoriDir;
// 	float HoriDistance = 0.f;
// 	HoriDiff.ToDirectionAndLength(HoriDir, HoriDistance);

// 	float Velocity = 0.5f * (FMath::Sqrt(Speed * Speed - 2.f * Gravity * HoriDistance) + Speed);
// 	return HoriDir * Velocity + FVector(0.f, 0.f, Speed - Velocity);
// }

UFUNCTION()
void InitArrivalPhysics(
	AActor StartActor,
	AActor TargetActor,
	FVector& LinearVelocity,
	FVector& LinearAcceleration,
	FVector& AngularVelocity,
	FVector& AngularAcceleration
)
{
	UPrimitiveComponent PrimComp = UPrimitiveComponent::Get(StartActor);

	// Gather ToTarget data.
	FVector ToTarget = TargetActor.GetActorLocation() - StartActor.GetActorLocation();
// 	ToTarget = ToTarget.VectorPlaneProject(FVector::UpVector);
	FVector ToTargetNormalized = ToTarget.GetSafeNormal();
	float ToTargetDistance = ToTarget.Size();

	// Calculate velocity towards target
	LinearVelocity = PrimComp.GetPhysicsLinearVelocity().ProjectOnTo(ToTarget);
// 	LinearVelocity = LinearVelocity.VectorPlaneProject(FVector::UpVector);

	// Calculate acceleration towards target
	FVector LinearAccelerationDirection = ToTarget.GetSafeNormal() * -1.f;
	float LinearAccelerationMagnitude = LinearVelocity.SizeSquared() / (2.f * ToTarget.Size());
	LinearAcceleration = LinearAccelerationDirection * LinearAccelerationMagnitude;

	// Calculate AngularVelocity towards target
	const FVector ToTargetAngular = ToTarget.CrossProduct(FVector::UpVector);
	AngularVelocity = PrimComp.GetPhysicsAngularVelocityInDegrees() * -1.f;
	AngularVelocity = AngularVelocity.ProjectOnTo(ToTargetAngular);

	// Calculate Angular acceleration towards target
	const float TimeUntilArrival = 2.f * ToTarget.Size() / LinearVelocity.Size();
	AngularAcceleration = AngularVelocity * (-1.f / TimeUntilArrival);

	// Turn off physics
	PrimComp.SetSimulatePhysics(false);
}

UFUNCTION()
void UpdateArrivalPhysics(
	AActor StartActor,
	AActor TargetActor,
	FVector& LinearVelocity,
	FVector& LinearAcceleration,
	FVector& AngularVelocity,
	FVector& AngularAcceleration,
	const float Dt
)
{
	// Update velocities
	LinearVelocity += (LinearAcceleration * Dt);
	AngularVelocity += AngularAcceleration * Dt;

	// Calculate delta moves
	FVector DeltaLinear = LinearVelocity * Dt + LinearAcceleration * 0.5f*Dt*Dt;
	FVector DeltaAngular = AngularVelocity * Dt + AngularAcceleration * 0.5f*Dt*Dt;
 	FRotator DeltaRotator = FRotator(DeltaAngular.Y, DeltaAngular.Z, DeltaAngular.X);		// This is make FRotator::MakeFromEuler()

	// Apply DeltaMoves
	StartActor.AddActorWorldRotation(DeltaRotator);
	StartActor.AddActorWorldOffset(DeltaLinear);
}

UFUNCTION()
bool TrajectoryTimeToReachHeight(float Velocity, float GravityMagnitude, float Height, float& OutTime)
{
	/*
	Parabola:
	-G/2 * (X - V/G)^2 + V^2/2G = A

	Which gives:
	X = V / G + sqrt((-2A / G) + (V / G)^2)
	*/
	float ValueToSqrt = ((-Height * 2.f) / GravityMagnitude + FMath::Square(Velocity / GravityMagnitude));
	if (ValueToSqrt < 0.f)
		return false;

	OutTime = Velocity / GravityMagnitude + FMath::Sqrt(ValueToSqrt);
	return true;
}

UFUNCTION()
bool TrajectoryPlaneIntersection(FVector Origin, FVector Velocity, FVector PlanePoint, float _GravityMagnitued, FVector& OutIntersection, FVector WorldUp = FVector::UpVector)
{
	const float GravityMagnitued = FMath::Abs(_GravityMagnitued);
	float Height = WorldUp.DotProduct(PlanePoint - Origin);

	float VertVelocity = 0.f;
	float HoriVelocity = 0.f;
	FVector VertDirection;
	FVector HoriDirection;
	SplitVectorIntoVerticalHorizontal(Velocity, WorldUp, VertDirection, VertVelocity, HoriDirection, HoriVelocity);

	float AirTime = 0.f;
	if (!TrajectoryTimeToReachHeight(VertVelocity, GravityMagnitued, Height, AirTime))
		return false;

	OutIntersection = Origin + HoriDirection * HoriVelocity * AirTime;
	OutIntersection = OutIntersection.ConstrainToPlane(WorldUp);
	OutIntersection += PlanePoint.ConstrainToDirection(WorldUp);
	return true;
}

UFUNCTION()
FVector TrajectoryPositionAfterTime(FVector Origin, FVector Velocity, float _GravityMagnitued, float Time, float TerminalSpeed = -1.f, FVector WorldUp = FVector::UpVector)
{
	const float GravityMagnitued = FMath::Abs(_GravityMagnitued);
	FVector HorizontalVelocity = Velocity.ConstrainToPlane(WorldUp);
	float VerticalSpeed = Velocity.DotProduct(WorldUp);
	float HeightGain = 0.f;

	if (TerminalSpeed <= 0.f)
		HeightGain = TrajectoryFunction(Time, GravityMagnitued, VerticalSpeed);
	else
		HeightGain = TrajectoryFunctionWithTerminalSpeed(Time, GravityMagnitued, VerticalSpeed, TerminalSpeed);

	return Origin + HorizontalVelocity * Time + WorldUp * HeightGain;
}

UFUNCTION()
FVector TrajectoryVelocityAfterTime(FVector Velocity, float _GravityMagnitued, float Time, float TerminalSpeed = -1.f, FVector WorldUp = FVector::UpVector)
{
	const float GravityMagnitued = FMath::Abs(_GravityMagnitued);
	FVector HorizontalVelocity = Velocity.ConstrainToPlane(WorldUp);
	float VerticalSpeed = Velocity.DotProduct(WorldUp);

	if (TerminalSpeed <= 0.f)
		return HorizontalVelocity + WorldUp * (VerticalSpeed - GravityMagnitued * Time);
	else
		return HorizontalVelocity + WorldUp * FMath::Max(-TerminalSpeed, VerticalSpeed - GravityMagnitued * Time);
}

UFUNCTION()
FVector TrajectoryHighestPoint(FVector Origin, FVector Velocity, float GravityMagnitude, FVector WorldUp = FVector::UpVector)
{
	// If gravity is negative, we will just go upwards forever, so no "highest" point....
	if (GravityMagnitude < 0.f)
		return FVector(MAX_flt);

	float VerticalSpeed = Velocity.DotProduct(WorldUp);

	// If we're moving downwards to start with, the origin is the highest point
	if (VerticalSpeed <= 0.f)
		return Origin;

	// Right!
	// So first, we want to find how long it will take until we reach 0 vertical speed
	float TimeToReachZero = VerticalSpeed / GravityMagnitude;

	// And.. thats the highest point. That's all folks.
	return TrajectoryPositionAfterTime(Origin, Velocity, GravityMagnitude, TimeToReachZero, -1.f, WorldUp);
}

UFUNCTION()
void DebugDrawTrajectory(FVector Origin, FVector Velocity, FVector Gravity, float TerminalSpeed = -1.f)
{
	FTrajectoryPoints Points = CalculateTrajectory(Origin, 5000.f, Velocity, Gravity.Size(), 1.5f, TerminalSpeed, -Gravity.GetSafeNormal());

	for(int i=0; i<Points.Positions.Num() - 1; ++i)
	{
		FVector Start = Points.Positions[i];
		FVector End = Points.Positions[i + 1];

		System::DrawDebugLine(Start, End);
	}
}
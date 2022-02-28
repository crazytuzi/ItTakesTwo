import Cake.Weapons.Sap.SapResponseComponent;
import Cake.Weapons.Sap.SapManager;
import Vino.Combustible.CombustibleComponent;

class UTreePhysicsComponent : USceneComponent
{

	// Stuff
	UPROPERTY()
	FVector AngularVelocity;

	UPROPERTY()
	FVector AngularAcceleration;

	UPROPERTY()
	FVector TotalRotation;

	UPROPERTY()
	FQuat Rotation;

	UPROPERTY()
	FRotator Rotator;

	UPROPERTY()
	FVector Velocity;

	UPROPERTY()
	FVector Acceleration;

	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FVector Gravity = FVector(0.f, 0.f, -980.f);

	UPROPERTY()
	float Drag = 1.f;

	UPROPERTY()
	FVector COM;

	// Simulation
	UPROPERTY()
	float SimulationRate = 60.f;

	float Accumulator = 0.f;
	float TimeStep = 1.f / SimulationRate;

	//

	USapResponseComponent SapComponent;
	UCombustibleComponent MatchComponent;

	FVector SapBalance;
	int AttachedSap;

	FVector PlayerBalance;
	int Players;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SapComponent = USapResponseComponent::GetOrCreate(Owner);
		MatchComponent = UCombustibleComponent::GetOrCreate(Owner);

		SapComponent.OnMassAdded.AddUFunction(this, n"AddMass");
		SapComponent.OnMassRemoved.AddUFunction(this, n"RemoveMass");
		MatchComponent.OnIgnited.AddUFunction(this, n"AddMatch");

		Rotation = GetComponentQuat();
		Location = GetWorldLocation();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
//		System::DrawDebugLine(GetWorldLocation(), GetWorldLocation() + Rotation.RotateVector(SapBalance), FLinearColor::Red);
//		System::DrawDebugLine(GetWorldLocation(), GetWorldLocation() + Gravity, FLinearColor::Green);
//		System::DrawDebugLine(GetWorldLocation(), GetWorldLocation() + Rotation.RotateVector(COM), FLinearColor::Blue);

		Accumulator += DeltaTime;

		while (Accumulator >= TimeStep)
		{
			// Simulate
			Simulate(TimeStep);
			
			Accumulator -= TimeStep;
		}

		float Alpha = Accumulator / TimeStep;

		Update();

	}

	UFUNCTION()
	void AddMass(FSapAttachTarget Where, float Mass)
	{
		Print("SapAdded", 1.f);
		FSapWeight Weight = SapGetTotalAttachedWeight(this);
		SapBalance = Weight.CenterOfMass * Weight.TotalMass;
	}

	UFUNCTION()
	void RemoveMass(FSapAttachTarget Where, float Mass)
	{
		Print("SapRemoved", 1.f);
		FSapWeight Weight = SapGetTotalAttachedWeight(this);
		SapBalance = Weight.CenterOfMass * Weight.TotalMass;
	}

	UFUNCTION()
	void AddMatch(AActor IgnitionSource, UPrimitiveComponent ComponentBeingIgnited, FHitResult HitResult)
	{
		Print("MatchAdded", 1.f);
	}

	UFUNCTION()
	void Simulate(float DeltaTime)
	{
		FVector Balance = COM + SapBalance + PlayerBalance;

		//Balance = Rotation.RotateVector(Balance);
		Balance = GetWorldRotation().RotateVector(Balance);

		System::DrawDebugLine(GetWorldLocation(), GetWorldLocation() + Balance, FLinearColor::Green);

		AngularAcceleration = Gravity.CrossProduct(Balance)
							- AngularVelocity * Drag;

		AngularVelocity += AngularAcceleration * DeltaTime;

		TotalRotation += AngularVelocity * DeltaTime;

		Print("Rotation: " + AngularVelocity, 0.f);

		//FQuat RotationDelta = FQuat(AngularVelocity, FMath::DegreesToRadians(AngularVelocity.Size() * DeltaTime * 0.001f));
		//FQuat RotationDelta = FQuat(AngularVelocity, AngularVelocity.Size() * DeltaTime);

		//Rotation = FQuat(AngularVelocity, FMath::DegreesToRadians(AngularVelocity.Size() * DeltaTime));
		FQuat RotationDelta = FQuat::MakeFromEuler(AngularVelocity * DeltaTime);
		Rotation += RotationDelta;
		FVector Axis;
		float Angle;
	//	RotationDelta.ToAxisAndAngle(Axis, Angle);

	}

	UFUNCTION()
	void Update()
	{
		SetWorldLocation(Location);
		SetWorldRotation(Rotation);
	}

}
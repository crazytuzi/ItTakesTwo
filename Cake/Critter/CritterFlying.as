import Peanuts.Spline.SplineComponent;

struct FFlyingCritter
{
	UStaticMeshComponent MeshComp;

	FVector Velocity;

	float RotateSpeed;

	FVector Position;

	FVector LastPosition;

	FVector Destination;
	FVector TargetVelocity;

	float MoveTimer;

	bool Moving;

	UHazeAkComponent AkComp;

	FHazeAudioEventInstance LoopingSoundInstance;
}

enum EFlyingCritterMovementStyle
{
    Random,
    Dragonfly,
    Circling,
};

const FHazeAkRTPC RTPC_CritterFlying_Velocity("Rtpc_World_Shared_Amb_Spot_CritterFlying_Velocity");

class ACritterFlying : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 8000.f;
	
    UPROPERTY(DefaultComponent)
	USphereComponent DebugSphere;
	default DebugSphere.bIsEditorOnly = true;
	default DebugSphere.CollisionProfileName = n"NoCollision";
	
    UPROPERTY(Category="Default")
	UStaticMesh Mesh;

    UPROPERTY(Category="Default")
	TArray<UMaterialInterface> RandomMaterials;
	
    UPROPERTY(Category="Default")
	int RandomMaterialTargetIndex = 0;
	
    UPROPERTY(Category="Default")
	bool RestrictToPlane = false;
	
    UPROPERTY(Category="Default|Dragonfly")
	bool DragonflyJudder = true;
    
	UPROPERTY(Category="Default")
	EFlyingCritterMovementStyle MovementStyle = EFlyingCritterMovementStyle::Dragonfly;

    UPROPERTY(Category="Default")
	float FlyRadius = 2500;
	
    UPROPERTY(Category="Default")
	int CritterCount = 4.0f;

    UPROPERTY(Category="Default|Random")
    float RandomFlySpeed = 200.0f;

    UPROPERTY(Category="Default|Circling")
    float CirclingFlySpeed = 800.0f;

    UPROPERTY(Category="Default")
    float Scale = 1;

    UPROPERTY(Category="Default|Circling")
    bool CirclingForceIntoRadius = false;

	TArray<FFlyingCritter> Critters;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LoopingSoundEvent;
	
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		DebugSphere.SphereRadius = FlyRadius;
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		if(Mesh == nullptr)
			return;
			
		Critters = TArray<FFlyingCritter>();
		for (int i = 0; i < CritterCount; i++)
		{
			FVector StartPos = GetActorLocation() + Math::GetRandomPointOnSphere() * FMath::RandRange(0.0f, 1.0f) * FlyRadius;

			auto NewMesh = Cast<UStaticMeshComponent>(CreateComponent(UStaticMeshComponent::StaticClass()));
			NewMesh.StaticMesh = Mesh;
			NewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
			NewMesh.CollisionProfileName = n"NoCollision";

			FFlyingCritter Critter;
			Critter.MeshComp = NewMesh;
			Critter.MeshComp.SetWorldLocation(StartPos);
			Critter.Position = StartPos;
			Critter.AkComp = UHazeAkComponent::Create(this);
			Critter.LoopingSoundInstance = Critter.AkComp.HazePostEvent(LoopingSoundEvent, PostEventType = EHazeAudioPostEventType::Ambience);
			Critter.MeshComp.SetWorldRotation(FRotator(0, FMath::RandRange(0, 360), 0));
			Critter.MoveTimer = 0.f;
			Critter.MeshComp.SetRelativeScale3D(FVector(Scale,Scale,Scale));
			if(MovementStyle == EFlyingCritterMovementStyle::Circling)
			{
				float RotationSpeed = FMath::RandRange(20.0f, 50.0f) / 800.0f;
				if(CirclingForceIntoRadius)
				{
					RotationSpeed = 360 / (FlyRadius*2.0);
				}

				Critter.RotateSpeed = RotationSpeed;
				Critter.RotateSpeed *= FMath::RandBool() ? -1 : 1;
			}
			if(RandomMaterials.Num() > 0)
			{
				int index = FMath::RandRange(0, RandomMaterials.Num() - 1);
				auto RandomMaterial = RandomMaterials[index];
				Critter.MeshComp.SetMaterial(RandomMaterialTargetIndex, RandomMaterial);
			}

			Critters.Add(Critter);
		}
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector ActorPos = GetActorLocation();

		for (int i = 0; i < CritterCount; i++)
		{
			FFlyingCritter& Critter = Critters[i];

			if(MovementStyle == EFlyingCritterMovementStyle::Random)
			{
				Critter.MoveTimer -= DeltaTime;
				if (Critter.MoveTimer <= 0.f)
				{
					Critter.MoveTimer = FMath::RandRange(1.f, 2.f);
					Critter.Destination = Critter.Position + Math::GetRandomPointOnSphere() * 100.f;
					Critter.TargetVelocity = Critter.Destination - Critter.LastPosition;
					Critter.TargetVelocity.Normalize();
				}

				Critter.Velocity = FMath::VInterpConstantTo(Critter.Velocity, Critter.TargetVelocity, DeltaTime, 1.f);

				FRotator Rotation = Critter.MeshComp.WorldRotation;
				if (!Critter.Velocity.IsNearlyZero())
				Rotation.Yaw = FRotator::MakeFromX(Critter.Velocity).Yaw;

				FVector WorldLocation = Critter.MeshComp.WorldLocation;
				WorldLocation += Critter.Velocity * 50.f * DeltaTime;

				Critter.MeshComp.SetWorldLocationAndRotation(WorldLocation, Rotation);
			}
			else if(MovementStyle == EFlyingCritterMovementStyle::Circling)
			{
				FRotator Rotation = Critter.MeshComp.WorldRotation;
				Rotation.Yaw += Critter.RotateSpeed * CirclingFlySpeed * DeltaTime;

				FVector WorldLocation = Critter.MeshComp.WorldLocation;
				WorldLocation += Rotation.ForwardVector * CirclingFlySpeed * DeltaTime;

				Critter.MeshComp.SetWorldLocationAndRotation(WorldLocation, Rotation);
			}
			else /*if(MovementStyle == EFlyingCritterMovementStyle::Dragonfly)*/
			{
				FVector WorldLocation = Critter.MeshComp.WorldLocation;

				if(Critter.Moving)
				{
					if(WorldLocation.Distance(ActorPos) > FlyRadius)
					{
						Critter.Velocity = ActorPos - WorldLocation; // Vector from current pos to sphere center.
					}
					Critter.Velocity.Normalize();
					WorldLocation += (Critter.Velocity * DeltaTime * 2000);
				}
				else
				{
					Critter.Velocity += Math::GetRandomPointOnSphere();
				
					// If critter is outside sphere, move it back.
					if(WorldLocation.Distance(ActorPos) > FlyRadius)
						Critter.Velocity = ActorPos - WorldLocation; // Vector from current pos to sphere center.

					Critter.Velocity.Normalize();

					if(DragonflyJudder)
						WorldLocation += (Critter.Velocity * DeltaTime * 100);
				}
				
				Critter.MoveTimer -= DeltaTime;

				if(Critter.MoveTimer <= 0)
				{
					Critter.Moving = !Critter.Moving;
					if(Critter.Moving)
					{
						Critter.MoveTimer = FMath::RandRange(0.1f, 0.2f);
					}
					else
					{
						Critter.MoveTimer = FMath::RandRange(0.2f, 8.0f);
					}
				}

				if(RestrictToPlane)
					WorldLocation.Z = ActorLocation.Z;

				Critter.MeshComp.SetWorldLocation(WorldLocation);
			}

			FVector CurrentPosition = Critter.MeshComp.WorldLocation;
			float velocity = (Critter.LastPosition - CurrentPosition).Size() / DeltaTime;
			Critter.LastPosition = CurrentPosition;
			Critter.AkComp.SetRTPCValue(RTPC_CritterFlying_Velocity, velocity);
			Critter.AkComp.SetWorldLocation(CurrentPosition);
		}
    }
}
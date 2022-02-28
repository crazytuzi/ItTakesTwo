import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketSettings;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketHole;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketManager;

class ULarvaBasketHoleAttachPoint : USceneComponent
{
}

class ALarvaBasketCylinder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent SpinRoot;

	UPROPERTY(EditInstanceOnly, Category = "Basket")
	float BaseSpeedMultiplier = 1.f;

	UPROPERTY(Category = "Basket")
	TArray<TSubclassOf<ALarvaBasketHole>> HoleTypes;

	UPROPERTY(Category = "Basket")
	int MinInterval = 1;

	UPROPERTY(Category = "Basket")
	int MaxInterval = 3;

	TArray<ALarvaBasketHole> Holes;

	FHazeAcceleratedFloat ControlSideError;
	float SyncTime = 0.f;
	FVector GameForward;
	int HoleSpawnInterval = 0;

	float SpeedMultiplier = 0.f;

	void GatherHoles(TArray<ALarvaBasketHole>& OutHoles)
	{
		OutHoles.Empty();

		TArray<AActor> Children;
		GetAttachedActors(Children);

		for(auto Child : Children)
		{
			auto Hole = Cast<ALarvaBasketHole>(Child);
			if (Hole == nullptr)
				continue;

			OutHoles.Add(Hole);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GameForward = LarvaBasketGetForwardVector();
		GatherHoles(Holes);

		for(auto Hole : Holes)
		{
			Hole.bIsFacingAway = (GameForward.DotProduct(Hole.ActorForwardVector) < -0.9f);
			Hole.AttachToComponent(SpinRoot, NAME_None, EAttachmentRule::KeepRelative);
		}

		HoleSpawnInterval = FMath::RandRange(MinInterval, MaxInterval);
	}

	UFUNCTION(CallInEditor, Category = "Basket")
	void SpawnHoles()
	{
		// Choose all the random hole types on the control side and send them over!
		// This is necessary since the actors need to be the same type to link up properly over network
		// So we cant RNG that shiet on both sides
		TArray<ULarvaBasketHoleAttachPoint> HolePoints;
		GetComponentsByClass(HolePoints);

		GatherHoles(Holes);
		for(auto PrevHole : Holes)
			PrevHole.DestroyActor();

		Holes.Empty();

		for(auto Point : HolePoints)
		{
			int TypeIndex = FMath::RandRange(0, HoleTypes.Num() - 1);
			auto Type = HoleTypes[TypeIndex];

			auto Hole = Cast<ALarvaBasketHole>(SpawnActor(Type, Level = GetLevel()));
			Hole.ActorTransform = Point.WorldTransform;
			Hole.AttachToComponent(SpinRoot, NAME_None, EAttachmentRule::KeepWorld);

			TypeIndex = (TypeIndex + 1) % HoleTypes.Num();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SpeedMultiplier = FMath::FInterpTo(SpeedMultiplier, LarvaBasketGameSpeedMultiplier(), 0.7f, DeltaTime);
		SpinRoot.AddRelativeRotation(FRotator(0.f, LarvaBasket::CylinderBaseSpeed * BaseSpeedMultiplier * SpeedMultiplier * DeltaTime, 0.f));

		// Disabled for now!
		// This is code to enable-disable holes based on if they're facing forward or backwards
		// But now, we want to try having them always enabled
		/*
		for(auto Hole : Holes)
		{
			bool bPrevFacingAway = Hole.bIsFacingAway;
			Hole.bIsFacingAway = (GameForward.DotProduct(Hole.ActorForwardVector) < -0.9f);

			if (bPrevFacingAway && !Hole.bIsFacingAway && HasControl())
			{
				if (HoleSpawnInterval-- == 0)
					NetSpawnHole(Hole);
			}

			if (!bPrevFacingAway && Hole.bIsFacingAway && Hole.bIsActive)
				Hole.DeactivateHole();
		}
		*/

		if (Network::IsNetworked())
		{
			if (HasControl())
			{
				if (Time::GameTimeSeconds > SyncTime)
				{
					NetSetControlSideRotation(SpinRoot.RelativeRotation.Yaw);
					SyncTime = Time::GameTimeSeconds + 5.f;
				}
			}
			else
			{
				float PrevError = ControlSideError.Value;
				ControlSideError.AccelerateTo(0.f, 7.f, DeltaTime);

				float CorrectionDelta = PrevError - ControlSideError.Value;
				SpinRoot.AddRelativeRotation(FRotator(0.f, CorrectionDelta, 0.f));
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetSpawnHole(ALarvaBasketHole Hole)
	{
		if (Hole.bIsActive)
			Hole.DeactivateHole();

		Hole.ActivateHole();
		HoleSpawnInterval = FMath::RandRange(MinInterval, MaxInterval);
	}

	UFUNCTION(NetFunction)
	void NetSetControlSideRotation(float ControlSideRotation)
	{
		if (HasControl())
			return;

		float LocalRotation = SpinRoot.RelativeRotation.Yaw;
		ControlSideError.Value = FMath::FindDeltaAngleDegrees(LocalRotation, ControlSideRotation);
	}

	UFUNCTION(DevFunction)
	void Desync()
	{
		SpinRoot.RelativeRotation = FRotator(0.f, FMath::RandRange(0.f, 360.f), 0.f);
	}
}
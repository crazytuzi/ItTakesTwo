import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongImpactComponent;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongInfo;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongTags;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongProjectile;

import void PowerfulSong_GatherImpacts(UPowerfulSongAbstractUserComponent, FPowerfulSongHitInfo&) from "Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongStatics";

#if EDITOR

const FConsoleVariable CVar_PowerfulSongDebugDraw("PowerfulSong.DebugDraw", 0);

#endif // EDITOR

class UPowerfulSongAbstractUserComponent : USceneComponent
{
#if EDITOR

	default PrimaryComponentTick.bStartWithTickEnabled = true;

#endif // EDITOR

	UPROPERTY(Category = Projectile)
	TSubclassOf<AActor> ProjectileClass = Asset("/Game/Blueprints/LevelSpecific/Music/Singing/PowerfulSong/BP_PowerfulSongSpeakerBlast.BP_PowerfulSongSpeakerBlast_C");


	// How far the song can reach.
	UPROPERTY(Category = Settings)
	protected float SongRange = 4000.0f;

	UPROPERTY(Category = Settings, meta = (ClampMin = 0.0, ClampMax = 180.0))
	protected float HorizontalAngle = 30.0f;

	UPROPERTY(Category = Settings, meta = (ClampMin = 0.0, ClampMax = 180.0))
	protected float VerticalAngle = 60.0f;

	UPROPERTY(Category = Settings, meta = (ClampMin = 0.0))
	protected float HorizontalOffset = 10.0f;

	UPROPERTY(Category = Settings, meta = (ClampMin = 0.0))
	protected float VerticalOffset = 10.0f;

	protected float GetHorizontalOffsetValue() const property { return HorizontalOffset; }
	protected float GetVerticalOffsetValue() const property { return VerticalOffset; }
	protected float GetHorizontalAngleValue() const property { return HorizontalAngle; }
	protected float GetVerticalAngleValue() const property { return VerticalAngle; }

	FVector GetPowerfulSongForward() const property { return ForwardVector; }
	FVector GetPowerfulSongStartLocation() const property { return WorldLocation; }

	float GetPowerfulSongRange() const property { return SongRange; }

	bool bWantsToShoot = false;

	void HandleSongImpact(FPowerfulSongInfo Info)
	{
		bWantsToShoot = true;
	}

	UFUNCTION(BlueprintCallable)
	void ShootPowerfulSong()
	{
		bWantsToShoot = true;
	}

	FVector GetRightOffset() const property
	{
		return GetPowerfulSongForward().RotateAngleAxis(GetHorizontalAngleValue(), GetPowerfulSongUpVector());
	}

	FVector GetLeftOffset() const property
	{
		return GetPowerfulSongForward().RotateAngleAxis(-GetHorizontalAngleValue(), GetPowerfulSongUpVector());
	}

	FVector GetUpOffset() const property
	{
		return GetPowerfulSongForward().RotateAngleAxis(GetVerticalAngleValue(), GetPowerfulSongRightVector());
	}

	FVector GetBottomOffset() const property
	{
		return GetPowerfulSongForward().RotateAngleAxis(-GetVerticalAngleValue(), GetPowerfulSongRightVector());
	}

	FVector GetRightNormal() const property
	{
		return GetRightOffset().CrossProduct(GetPowerfulSongUpVector()).GetSafeNormal();
	}

	FVector GetLeftNormal() const property
	{
		return GetLeftOffset().CrossProduct(GetPowerfulSongUpVector()).GetSafeNormal();
	}

	FVector GetUpNormal() const property
	{
		return GetUpOffset().CrossProduct(GetPowerfulSongRightVector()).GetSafeNormal();
	}

	FVector GetBottomNormal() const property
	{
		return GetBottomOffset().CrossProduct(GetPowerfulSongRightVector()).GetSafeNormal();
	}

	FVector GetRightStartLocation() const property
	{
		return GetPowerfulSongStartLocation() + (GetPowerfulSongRightVector() * GetHorizontalOffsetValue());
	}

	FVector GetLeftStartLocation() const property
	{
		return GetPowerfulSongStartLocation() - (GetPowerfulSongRightVector() * GetHorizontalOffsetValue());
	}

	FVector GetUpStartLocation() const property
	{
		return GetPowerfulSongStartLocation() - (GetPowerfulSongUpVector() * GetVerticalOffsetValue());
	}

	FVector GetBottomStartLocation() const property
	{
		return GetPowerfulSongStartLocation() + (GetPowerfulSongUpVector() * GetVerticalOffsetValue());
	}

	FVector GetPowerfulSongRightVector() const property
	{
		return RightVector;
	}

	FVector GetPowerfulSongUpVector() const property
	{
		return UpVector;
	}

	bool IsPointInsideCone(const FVector& Point) const
	{
		return IsPointInsideCone(Point, GetRightNormal(), -GetLeftNormal(), GetUpNormal(), -GetBottomNormal());
	}

	bool IsPointInsideCone(const FVector& Point, const FVector& InRightNormal, const FVector& InLeftNormal, const FVector& InUpNormal, const FVector& InBottomNormal) const
	{
		const FVector RightDirToTarget = (Point - GetRightStartLocation()).GetSafeNormal();
		const FVector LeftDirToTarget = (Point - GetLeftStartLocation()).GetSafeNormal();
		const FVector UpDirToTarget = (Point - GetUpStartLocation()).GetSafeNormal();
		const FVector BottomToTarget = (Point - GetBottomStartLocation()).GetSafeNormal();

		if(RightDirToTarget.DotProduct(InRightNormal) > 0.0f 
		&& LeftDirToTarget.DotProduct(InLeftNormal) > 0.0f
		&& UpDirToTarget.DotProduct(InUpNormal) > 0.0f 
		&& BottomToTarget.DotProduct(InBottomNormal) > 0.0f)
		{
			return true;
		}

		return false;
	}

	bool FindClosestPoint(FVector& ClosestPoint, const UDEPRECATED_PowerfulSongImpactComponent TargetImpact) const
	{
		ClosestPoint = FVector::ZeroVector;
		const FVector StartLocation = GetPowerfulSongStartLocation();
		const float DistanceToTarget = TargetImpact.Owner.ActorLocation.Distance(StartLocation);
		FVector LocationToTest = StartLocation + (GetPowerfulSongForward() * DistanceToTarget);
		TArray<UActorComponent> PrimitiveComponents = TargetImpact.Owner.GetComponentsByClass(UMeshComponent::StaticClass());
		float ClosestDistanceSq = Math::MaxFloat;

		{
			FHitResult Hit;
			TArray<EObjectTypeQuery> ObjectTypesTemp;
			ObjectTypesTemp.Add(EObjectTypeQuery::WorldStatic);
			TArray<AActor> Ignore;
			Ignore.Add(Game::GetMay());
			Ignore.Add(Game::GetCody());
			Ignore.Add(Owner);
			System::LineTraceSingle(StartLocation, LocationToTest, ETraceTypeQuery::Visibility, false, Ignore, EDrawDebugTrace::None, Hit, false);
			if(Hit.bBlockingHit)
			{
				LocationToTest = Hit.ImpactPoint + (Hit.ImpactNormal * 50.0f);
			}
		}

#if EDITOR

	if(CVar_PowerfulSongDebugDraw.GetInt() == 1)
	{
		System::DrawDebugSphere(LocationToTest, 50.0f, 12, FLinearColor::Green);
	}
			
#endif // EDITOR

		if(PrimitiveComponents.Num() > 0)
		{
			FVector ClosestPointTemp;
			for(UActorComponent ActorComp : PrimitiveComponents)
			{
				UPrimitiveComponent Prim = Cast<UPrimitiveComponent>(ActorComp);
				
				//TODO: Temporary hack to avoid certain meshes
				if(Prim.CollisionProfileName == n"NoCollision")
				{
					continue;
				}

				const float DistanceToPoint = Prim.GetClosestPointOnCollision(LocationToTest, ClosestPointTemp);

				if(DistanceToPoint < 0.0f)
				{
					continue;
				}

				const float DistanceSq = LocationToTest.DistSquared(ClosestPointTemp);
				if(DistanceSq < ClosestDistanceSq)
				{
					ClosestPoint = ClosestPointTemp;
					ClosestDistanceSq = DistanceSq;
				}
			}
		}
		else
		{
			// If no meshes are available, exit.
			return false;
		}

		return true;
	}

#if EDITOR

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(CVar_PowerfulSongDebugDraw.GetInt() != 1)
		{
			return;
		}

		const float Length = SongRange;
		const FVector StartLocation = WorldLocation;

		const FVector LocalRightStartLocation = GetRightStartLocation();
		const FVector LocalLeftStartLocation = GetLeftStartLocation();
		const FVector LocalUpStartLocation = GetUpStartLocation();
		const FVector LocalBottomStartLocation = GetBottomStartLocation();

		const FVector LocalRightOffset = GetRightOffset();
		const FVector LocalLeftOffset = GetLeftOffset();
		const FVector LocalUpOffset = GetUpOffset();
		const FVector LocalBottomOffset = GetBottomOffset();

		const float ArrowSize = 10.0f;

		System::DrawDebugArrow(LocalRightStartLocation, LocalRightStartLocation + (LocalRightOffset * Length), ArrowSize, FLinearColor::Green, DeltaTime);
		System::DrawDebugArrow(LocalLeftStartLocation, LocalLeftStartLocation + (LocalLeftOffset * Length), ArrowSize, FLinearColor::Green, DeltaTime);

		System::DrawDebugArrow(LocalUpStartLocation, LocalUpStartLocation + (LocalUpOffset * Length), ArrowSize, FLinearColor::Blue);
		System::DrawDebugArrow(LocalBottomStartLocation, LocalBottomStartLocation + (LocalBottomOffset * Length), ArrowSize, FLinearColor::Blue);
	
		const float NormalLocationLength = Length * 0.5f;
		const float NormalLength = 30.0f;

		const FVector RightNormalStartLocation = LocalRightStartLocation + (LocalRightOffset * NormalLocationLength);
		const FVector LeftNormalStartLocation = LocalLeftStartLocation + (LocalLeftOffset * NormalLocationLength);
		const FVector UpNormalStartLocation = LocalUpStartLocation + (LocalUpOffset * NormalLocationLength);
		const FVector BottomNormalStartLocation = LocalBottomStartLocation + (LocalBottomOffset * NormalLocationLength);

		System::DrawDebugArrow(RightNormalStartLocation, RightNormalStartLocation + (GetRightNormal() * NormalLength), ArrowSize, FLinearColor::Red, DeltaTime);
		System::DrawDebugArrow(LeftNormalStartLocation, LeftNormalStartLocation - (GetLeftNormal() * NormalLength), ArrowSize, FLinearColor::Red, DeltaTime);
		System::DrawDebugArrow(UpNormalStartLocation, UpNormalStartLocation + (GetUpNormal() * NormalLength), ArrowSize, FLinearColor::Red, DeltaTime);
		System::DrawDebugArrow(BottomNormalStartLocation, BottomNormalStartLocation - (GetBottomNormal() * NormalLength), ArrowSize, FLinearColor::Red, DeltaTime);

		System::DrawDebugArrow(WorldLocation, WorldLocation + (ForwardVector * PowerfulSongRange), ArrowSize, FLinearColor::LucBlue, DeltaTime);
	
		FPowerfulSongHitInfo HitInfo;
		PowerfulSong_GatherImpacts(this, HitInfo);

		for(FPowerfulSongImpactLocationInfo Impact : HitInfo.Impacts)
		{
			System::DrawDebugSphere(Impact.ImpactLocation, 100.0f, 12, FLinearColor::LucBlue, DeltaTime);
		}
	}

#endif // EDITOR
}

// imported in PowerfulSongImpactComponent
bool IsPointInsideCone(AHazePlayerCharacter Player, const FVector& Point)
{
	UPowerfulSongAbstractUserComponent SongUser = UPowerfulSongAbstractUserComponent::Get(Player);

	if(SongUser != nullptr)
	{
		return SongUser.IsPointInsideCone(Point);
	}

	return false;
}

// imported in PowerfulSongImpactComponent
bool FindClosestPointOnImpact(AHazePlayerCharacter Player, const UDEPRECATED_PowerfulSongImpactComponent ImpactComponent, FVector& ClosestPoint)
{
	ClosestPoint = FVector::ZeroVector;
	UPowerfulSongAbstractUserComponent SongUser = UPowerfulSongAbstractUserComponent::Get(Player);

	if(SongUser != nullptr)
	{
		return SongUser.FindClosestPoint(ClosestPoint, ImpactComponent);
	}

	return false;
}

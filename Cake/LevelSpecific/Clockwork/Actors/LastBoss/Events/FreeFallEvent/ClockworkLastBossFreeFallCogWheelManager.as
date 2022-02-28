import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.FreeFallEvent.ClockworkLastBossFreeFallCogWheel;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.FreeFallEvent.ClockworkLastBossFreeFallCogWall;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.FreeFallEvent.ClockworkLastBossFreeFallCog;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.FreeFallEvent.ClockworkLastBossFreeFallBar;

enum ECogSquarePosition
{
	TopLeft,
	TopRight,
	BottomLeft,
	BottomRight
}

struct FClockworkLastBossFreeFallCogLayer
{
	float CogHeight = 0.f;
	TArray<FVector2D> CogPositions;

	FClockworkLastBossFreeFallCogLayer opAdd(const FClockworkLastBossFreeFallCogLayer& Other) const
	{
		FClockworkLastBossFreeFallCogLayer NewLayer;
		NewLayer.CogPositions.Append(CogPositions);
		NewLayer.CogPositions.Append(Other.CogPositions);
		return NewLayer;
	}

	FClockworkLastBossFreeFallCogLayer& opAddAssign(const FClockworkLastBossFreeFallCogLayer& Other)
	{
		CogPositions.Append(Other.CogPositions);
		return this;
	}
};

struct FClockworkLastBossFreeFallCogSequence
{
	TArray<FClockworkLastBossFreeFallCogLayer> Layers;
	float BuildHeight = 0.f;
	float BuildSpacing = 5000.f;

	FClockworkLastBossFreeFallCogSequence()
	{
		// Total Distance = 3500 u/s (speed) * 35 s (duration)
		//   = 125 000

		// Start height 20 000, so spaced 5000 we have 20 layers
		BuildHeight += 20000.f;


		AddLayer(CogLayer_Square());
		AddLayer(CogLayer_Diamond());
		AddLayer(CogLayer_PlusInverted());
		AddLayer(CogLayer_FilledSquare(ECogSquarePosition::BottomLeft));
		AddLayer(CogLayer_FilledSquare(ECogSquarePosition::BottomRight));
		AddLayer(CogLayer_FilledSquare(ECogSquarePosition::TopLeft));
		AddLayer(CogLayer_FilledSquare(ECogSquarePosition::TopRight));
		AddLayer(CogLayer_Cross(4));
		AddLayer(CogLayer_Cross(8));
		AddLayer(CogLayer_Plus());
		AddLayer(CogLayer_Line(4, FVector2D(0.f, 0.5f), FVector2D(1.f, 0.5f)));
		AddLayer(CogLayer_Cross(4));
		AddLayer(CogLayer_Cross(8));
		AddLayer(CogLayer_Cross(4));
		AddLayer(CogLayer_Cross(8));
		AddLayer(CogLayer_Cross(4));
		AddLayer(CogLayer_Cross(8));
		AddLayer(CogLayer_Cross(4));
		AddLayer(CogLayer_Cross(8));
		AddLayer(CogLayer_Cross(4));
	}

	void AddLayer(const FClockworkLastBossFreeFallCogLayer& InLayer)
	{
		Layers.Add(InLayer);

		auto& Layer = Layers[Layers.Num() - 1];
		Layer.CogHeight = BuildHeight;

		BuildHeight += BuildSpacing;
	}
};

class AClockworkLastBossFreeFallCogWheelManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	AClockworkLastBossFreeFallCogWall CogWall;
	
	UPROPERTY()
	TSubclassOf<AClockworkLastBossFreeFallCogWheel> CogClass;

	FClockworkLastBossFreeFallCogSequence Sequence;
	TArray<AClockworkLastBossFreeFallCogWheel> SpawnedCogs;
	int SpawnedCogLayer = 0;

	bool bActive = false;
	bool bCogsActive = false;

	float PlayerHeight = 0.f;
	float StartPlayerHeight = -1.f;

	int CogCount = 0;

	FVector TopLeftPosition;
	FVector BotRightPosition;

	// Distance that cogs are spawned below the players
	float SpawnAheadDistance = 25000.f;
	// Distance that cogs behind the players are destroyed
	float DestroyAfterDistance = 1000.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void SetCogBoundaries(USceneComponent TopLeft, USceneComponent BotRight)
	{
		TopLeftPosition.X = FMath::Min(TopLeft.WorldLocation.X, BotRight.WorldLocation.X);
		TopLeftPosition.Y = FMath::Min(TopLeft.WorldLocation.Y, BotRight.WorldLocation.Y);

		BotRightPosition.X = FMath::Max(TopLeft.WorldLocation.X, BotRight.WorldLocation.X);
		BotRightPosition.Y = FMath::Max(TopLeft.WorldLocation.Y, BotRight.WorldLocation.Y);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;

		// // Spawn any new cogs that we haven't spawned yet
		// float FallDistance = (StartPlayerHeight - PlayerHeight);
		// if (SpawnedCogLayer < Sequence.Layers.Num())
		// {
		// 	auto& Layer = Sequence.Layers[SpawnedCogLayer];
		// 	if (Layer.CogHeight < FallDistance + SpawnAheadDistance)
		// 	{
		// 		for (const FVector2D& Position : Layer.CogPositions)
		// 			SpawnCog(StartPlayerHeight - Layer.CogHeight, Position);

		// 		SpawnedCogLayer += 1;
		// 	}
		// }

		// // Destroy cogs that are too far behind the players
		// for (int i = 0, Count = SpawnedCogs.Num(); i < Count; ++i)
		// {
		// 	auto Cog = SpawnedCogs[i];
		// 	if (Cog == nullptr)
		// 	{
		// 		SpawnedCogs.RemoveAt(i);
		// 		--i; --Count;
		// 		continue;
		// 	}

		// 	if (Cog.SpawnedHeight > PlayerHeight + DestroyAfterDistance)
		// 	{
		// 		Cog.DestroyActor();
		// 		SpawnedCogs.RemoveAt(i);
		// 		--i; --Count;
		// 		continue;
		// 	}
		// }
	}

	void SpawnCog(float ZHeight, FVector2D Position)
	{
		FVector WorldLocation;
		WorldLocation.Z = ZHeight;
		WorldLocation.X = FMath::Lerp(TopLeftPosition.X, BotRightPosition.X, Position.Y);
		WorldLocation.Y = FMath::Lerp(TopLeftPosition.Y, BotRightPosition.Y, Position.X);

		//System::DrawDebugPoint(WorldLocation, Duration = 3.f, Size = 20.f);

		auto Cog = Cast<AClockworkLastBossFreeFallCogWheel>(
			SpawnActor(CogClass, WorldLocation, bDeferredSpawn = true)
		);

		Cog.SpawnedHeight = ZHeight;
		Cog.MakeNetworked(this, CogCount++);
		FinishSpawningActor(Cog);

		SpawnedCogs.Add(Cog);
		Cog.ActivateCogWheel();
	}

	UFUNCTION()
	void SetManagerActive(bool bNewActive)
	{
		bActive = bNewActive;
		CogWall.SetWallActivated(bNewActive);
		
		TArray<AClockworkLastBossFreeFallCog> CogArray;
		GetAllActorsOfClass(CogArray);
		for(auto Cog : CogArray)
		{
			if (bNewActive && Cog.IsActorDisabled(nullptr))
				Cog.EnableActor(nullptr);
			else if (!bNewActive && !Cog.IsActorDisabled(nullptr))
				Cog.DisableActor(nullptr);
		}

		TArray<AClockworkLastBossFreeFallBar> BarArray;
		GetAllActorsOfClass(BarArray);
		for(auto Bar : BarArray)
		{
			if (bNewActive && Bar.IsActorDisabled(nullptr))
				Bar.EnableActor(nullptr);
			else if (!bNewActive && !Bar.IsActorDisabled(nullptr))
				Bar.DisableActor(nullptr);
		}
	}

	void SetCurrentHeight(float ZHeight)
	{
		PlayerHeight = ZHeight;
		if (StartPlayerHeight == -1.f)
			StartPlayerHeight = ZHeight;
	}
}

FClockworkLastBossFreeFallCogLayer CogLayer_Line(int CogCount, FVector2D StartPos, FVector2D EndPos)
{
	FClockworkLastBossFreeFallCogLayer Layer;
	float Spacing = 1.f / float(CogCount);
	float Alpha = 0.5f * Spacing;

	for (int i = 0; i < CogCount; ++i)
	{
		Layer.CogPositions.Add(
			FVector2D(StartPos.X * (1.f - Alpha) + EndPos.X * Alpha,
					  StartPos.Y * (1.f - Alpha) + EndPos.Y * Alpha)
		);
		Alpha += Spacing;
	}

	return Layer;
}

FClockworkLastBossFreeFallCogLayer CogLayer_Cross(int CogCount)
{
	FClockworkLastBossFreeFallCogLayer Layer;
	Layer += CogLayer_Line(CogCount / 4, FVector2D(0.f, 0.f), FVector2D(0.5f, 0.5f));
	Layer += CogLayer_Line(CogCount / 4, FVector2D(1.f, 0.f), FVector2D(0.5f, 0.5f));
	Layer += CogLayer_Line(CogCount / 4, FVector2D(0.f, 1.f), FVector2D(0.5f, 0.5f));
	Layer += CogLayer_Line(CogCount / 4, FVector2D(1.f, 1.f), FVector2D(0.5f, 0.5f));
	return Layer;
}

FClockworkLastBossFreeFallCogLayer CogLayer_Plus()
{
	FClockworkLastBossFreeFallCogLayer Layer;
	Layer.CogPositions.Add(FVector2D(0.25f, 0.5f));
	Layer.CogPositions.Add(FVector2D(0.5f, 0.5f));
	Layer.CogPositions.Add(FVector2D(0.75f, 0.5f));
	Layer.CogPositions.Add(FVector2D(0.5f, 0.25f));
	Layer.CogPositions.Add(FVector2D(0.5f, 0.75f));
	return Layer;
}

FClockworkLastBossFreeFallCogLayer CogLayer_PlusInverted()
{
	FClockworkLastBossFreeFallCogLayer Layer;
	Layer.CogPositions.Add(FVector2D(0.5f, 0.f));
	Layer.CogPositions.Add(FVector2D(0.75f, 0.25f));
	Layer.CogPositions.Add(FVector2D(1.f, 0.5f));
	Layer.CogPositions.Add(FVector2D(0.75f, 0.75f));
	Layer.CogPositions.Add(FVector2D(0.5f, 1.f));
	Layer.CogPositions.Add(FVector2D(0.25f, 0.75f));
	Layer.CogPositions.Add(FVector2D(0.f, 0.5f));
	Layer.CogPositions.Add(FVector2D(0.25f, 0.25f));
	Layer.CogPositions.Add(FVector2D(1.f, 0.f));
	Layer.CogPositions.Add(FVector2D(0.75f, 0.f));
	Layer.CogPositions.Add(FVector2D(1.f, 0.25f));
	Layer.CogPositions.Add(FVector2D(1.f, 0.75f));
	Layer.CogPositions.Add(FVector2D(1.f, 1.f));
	Layer.CogPositions.Add(FVector2D(0.75f, 1.f));
	Layer.CogPositions.Add(FVector2D(0.25f, 0.f));
	Layer.CogPositions.Add(FVector2D(0.f, 0.f));
	Layer.CogPositions.Add(FVector2D(0.f, 0.25f));
	Layer.CogPositions.Add(FVector2D(0.f, 0.75f));
	Layer.CogPositions.Add(FVector2D(0.25f, 1.f));
	Layer.CogPositions.Add(FVector2D(0.f, 1.f));
	return Layer;
}

FClockworkLastBossFreeFallCogLayer CogLayer_Square()
{
	FClockworkLastBossFreeFallCogLayer Layer;
	Layer.CogPositions.Add(FVector2D(0.0f, 0.0f));
	Layer.CogPositions.Add(FVector2D(0.0f, 0.25f));
	Layer.CogPositions.Add(FVector2D(0.0f, 0.5f));
	Layer.CogPositions.Add(FVector2D(0.0f, 0.75f));
	Layer.CogPositions.Add(FVector2D(0.0f, 1.f));
	
	Layer.CogPositions.Add(FVector2D(0.25f, 0.f));
	Layer.CogPositions.Add(FVector2D(0.5f, 0.f));
	Layer.CogPositions.Add(FVector2D(0.75f, 0.f));
	Layer.CogPositions.Add(FVector2D(1.f, 0.f));
	
	Layer.CogPositions.Add(FVector2D(1.f, 0.25f));
	Layer.CogPositions.Add(FVector2D(1.f, 0.5f));
	Layer.CogPositions.Add(FVector2D(1.f, 0.75f));
	Layer.CogPositions.Add(FVector2D(1.f, 1.f));
	
	Layer.CogPositions.Add(FVector2D(0.75f, 1.f));
	Layer.CogPositions.Add(FVector2D(0.5f, 1.f));
	Layer.CogPositions.Add(FVector2D(0.25f, 1.f));
	return Layer;
}

FClockworkLastBossFreeFallCogLayer CogLayer_Diamond()
{
	FClockworkLastBossFreeFallCogLayer Layer;
	Layer.CogPositions.Add(FVector2D(0.5f, 0.f));
	Layer.CogPositions.Add(FVector2D(0.75f, 0.25f));
	Layer.CogPositions.Add(FVector2D(1.f, 0.5f));
	Layer.CogPositions.Add(FVector2D(0.75f, 0.75f));
	Layer.CogPositions.Add(FVector2D(0.5f, 1.f));
	Layer.CogPositions.Add(FVector2D(0.25f, 0.75f));
	Layer.CogPositions.Add(FVector2D(0.f, 0.5f));
	Layer.CogPositions.Add(FVector2D(0.25f, 0.25f));
	return Layer;
}

FClockworkLastBossFreeFallCogLayer CogLayer_FilledSquare(ECogSquarePosition SquarePosition)
{
	FClockworkLastBossFreeFallCogLayer Layer;

	switch(SquarePosition)
	{
		case ECogSquarePosition::BottomLeft:
		{
			Layer.CogPositions.Add(FVector2D(1.f, 0.5f));
			Layer.CogPositions.Add(FVector2D(.75f, 0.5f));
			Layer.CogPositions.Add(FVector2D(.5f, .5f));
			Layer.CogPositions.Add(FVector2D(1.f, .75f));
			Layer.CogPositions.Add(FVector2D(.75f, .75f));
			Layer.CogPositions.Add(FVector2D(.5f, .75f));
			Layer.CogPositions.Add(FVector2D(1.f, 1.f));
			Layer.CogPositions.Add(FVector2D(.75f, 1.f));
			Layer.CogPositions.Add(FVector2D(.5f, 1.f));
			break;
		}

		case ECogSquarePosition::BottomRight:
		{
			Layer.CogPositions.Add(FVector2D(.5f, 1.f));
			Layer.CogPositions.Add(FVector2D(.25f, 1.f));
			Layer.CogPositions.Add(FVector2D(0.f, 1.f));
			Layer.CogPositions.Add(FVector2D(0.5f, .75f));
			Layer.CogPositions.Add(FVector2D(0.25f, .75f));
			Layer.CogPositions.Add(FVector2D(0.f, .75f));
			Layer.CogPositions.Add(FVector2D(0.5f, .5f));
			Layer.CogPositions.Add(FVector2D(0.25f, .5f));
			Layer.CogPositions.Add(FVector2D(0.f, .5f));
			break;
		}

		case ECogSquarePosition::TopLeft:
		{
			Layer.CogPositions.Add(FVector2D(1.f, 0.f));
			Layer.CogPositions.Add(FVector2D(.75f, 0.f));
			Layer.CogPositions.Add(FVector2D(.5f, 0.f));
			Layer.CogPositions.Add(FVector2D(1.f, 0.25f));
			Layer.CogPositions.Add(FVector2D(.75f, 0.25f));
			Layer.CogPositions.Add(FVector2D(.5f, 0.25f));
			Layer.CogPositions.Add(FVector2D(1.f, 0.5f));
			Layer.CogPositions.Add(FVector2D(.75f, 0.5f));
			Layer.CogPositions.Add(FVector2D(.5f, 0.5f));
			break;
		}

		case ECogSquarePosition::TopRight:
		{
			Layer.CogPositions.Add(FVector2D(.5f, 0.f));
			Layer.CogPositions.Add(FVector2D(.25f, 0.f));
			Layer.CogPositions.Add(FVector2D(0.f, 0.f));
			Layer.CogPositions.Add(FVector2D(0.5f, 0.25f));
			Layer.CogPositions.Add(FVector2D(0.25f, 0.25f));
			Layer.CogPositions.Add(FVector2D(0.f, 0.25f));
			Layer.CogPositions.Add(FVector2D(0.5f, 0.5f));
			Layer.CogPositions.Add(FVector2D(0.25f, 0.5f));
			Layer.CogPositions.Add(FVector2D(0.f, 0.5f));
			break;
		}
	}
	return Layer;
}

FClockworkLastBossFreeFallCogLayer CogLayer_Test()
{
	FClockworkLastBossFreeFallCogLayer Layer;
	Layer.CogPositions.Add(FVector2D(0.0f, 0.0f));
	Layer.CogPositions.Add(FVector2D(1.0f, 1.0f));
	return Layer;
}
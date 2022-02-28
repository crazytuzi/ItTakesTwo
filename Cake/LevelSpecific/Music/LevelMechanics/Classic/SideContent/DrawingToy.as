import Vino.LevelSpecific.Garden.ValveTurnInteractionActor;
import Cake.Environment.GPUSimulations.PaintablePlane;

class ADrawingToy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	UStaticMeshComponent Mesh;
	UPROPERTY(DefaultComponent, Attach = Mesh)	
	USceneComponent DrawLocation;
	
	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 4000.f;

	UPROPERTY()
	AActor DebugActor;
	UPROPERTY(EditInstanceOnly)
	APaintablePlane PaintablePlane;

	UPROPERTY()
	AValveTurnInteractionActor LeftInteraction;
	UPROPERTY()
	AValveTurnInteractionActor RightInteraction;


	FHazeAcceleratedFloat AcceleratedFloatRecentInputLeft;
	FHazeAcceleratedFloat AcceleratedFloatRecentInputRight;

	float XCurrentValue = 0;
	float YCurrentValue = 0;

	float ClearPaintTimer = 1.0f;
	float ClearPaintTimerTemp;
	bool bClearingPaint = false;
	FVector LastDrawLocation;
	UMaterialInstanceDynamic DynamicMaterial;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent LeftRightSync;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent UpDownSync;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LeftInteraction.SyncComponent.Value = 50;
		RightInteraction.SyncComponent.Value = 50;
		AcceleratedFloatRecentInputLeft.Value = LeftInteraction.SyncComponent.Value;
		AcceleratedFloatRecentInputRight.Value = RightInteraction.SyncComponent.Value;
		ResetPaintablePlane();
		DynamicMaterial = Mesh.CreateDynamicMaterialInstance(0);
		DynamicMaterial.SetTextureParameterValue(n"RenderTarget", PaintablePlane.SimulationBuffer.ActiveTarget);
		DynamicMaterial.SetVectorParameterValue(n"PaintablePlaneTransform", PaintablePlane.WitherPlaneTransform);

		if(World.HasControl())
		{	
			auto Player = Game::GetMay().HasControl() ? Game::GetMay() : Game::GetCody();
			LeftRightSync.OverrideControlSide(Player);
			LeftRightSync.OverrideControlSide(Player);
		}
		else
		{
			auto Player = !Game::GetMay().HasControl() ? Game::GetMay() : Game::GetCody();
			LeftRightSync.OverrideControlSide(Player);
			LeftRightSync.OverrideControlSide(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//PrintToScreen("LeftInteraction.SyncComponent.Value " + LeftInteraction.SyncComponent.Value);
		//PrintToScreen("RightInteraction.SyncComponent.Value " + RightInteraction.SyncComponent.Value);
		//PrintToScreen("AcceleratedFloatRecentInputLeft.Value " + AcceleratedFloatRecentInputLeft.Value);
		//PrintToScreen("AcceleratedFloatRecentInputRight.Value " + AcceleratedFloatRecentInputRight.Value);
		//PrintToScreen("AutoDisableTimerTemp " + AutoDisableTimerTemp);
		//PrintToScreen("bDrawingToyActive " + bDrawingToyActive);
		//PrintToScreen("YCurrentValue" + YCurrentValue);
		//PrintToScreen("XCurrentValue " + XCurrentValue);

		if(HasControl())
		{
			AcceleratedFloatRecentInputLeft.SpringTo(LeftInteraction.SyncComponent.Value + 0.1, 70, 1, DeltaSeconds);
			AcceleratedFloatRecentInputRight.SpringTo(RightInteraction.SyncComponent.Value + 0.1, 70, 1, DeltaSeconds);

			YCurrentValue = LeftInteraction.SyncComponent.Value - 50;
			XCurrentValue = RightInteraction.SyncComponent.Value - 50;
			DrawLocation.SetRelativeLocation(FVector(-(XCurrentValue + 3.5) * 9.9, -(YCurrentValue + 0) * 10, 0));

			LeftRightSync.Value = XCurrentValue;
			UpDownSync.Value = YCurrentValue;
		}
		else
		{
			YCurrentValue = UpDownSync.Value;
			XCurrentValue = LeftRightSync.Value;
			DrawLocation.SetRelativeLocation(FVector(-(XCurrentValue + 3.5) * 9.9, -(YCurrentValue + 0) * 10, 0));
		}


		if(bClearingPaint)
		{
			PaintablePlane.LerpAndDrawTexture(GetActorLocation(), 900, FLinearColor(0.f, 0.f, 0.f, 0.f),  FLinearColor(3.f, 0.f, 0.f, 0.f) * DeltaSeconds, true, nullptr, false, FLinearColor(1.f, 1.f, 1.f));
			ClearPaintTimerTemp -= DeltaSeconds;
			if(ClearPaintTimerTemp < 0)
			{
				bClearingPaint = false;
				ClearPaintTimerTemp = ClearPaintTimer;
			}
		}
		else
		{
			if(LastDrawLocation != DrawLocation.GetWorldLocation())
			{
				PaintablePlane.LerpAndDrawTexture(DrawLocation.GetWorldLocation(), 10, FLinearColor(72.f, 0.f, 0.f, 0.f),  FLinearColor(25.0f, 0.f, 0.f, 0.f) * DeltaSeconds, true, nullptr, true, FLinearColor(1.45f,1.45f,1.45f));
				LastDrawLocation = DrawLocation.GetWorldLocation();
			}
		}

		if(DebugActor != nullptr)
			DebugActor.SetActorLocation(DrawLocation.GetWorldLocation());
	}


	UFUNCTION()
	void ResetPaintablePlane()
	{
		bClearingPaint = true;
	}
}


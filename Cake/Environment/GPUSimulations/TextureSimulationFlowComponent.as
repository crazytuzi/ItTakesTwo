import Cake.Environment.GPUSimulations.TextureSimulationComponent;

class UTextureSimulationFlowComponent : UTextureSimulationComponent
{
	UPROPERTY(Category = "Input")
	AActor SmudgeLocation;

	UPROPERTY(Category = "Input")
	AActor PaintLocation;

	UPROPERTY(Category = "Input")
	FLinearColor PaintColor = FLinearColor(0.0f, 1.0f, 0.0f);

	UPROPERTY(Category = "Input")
	FLinearColor BrownColor = FLinearColor(0.2f, 0.1f, 0.0f);


	UPROPERTY(Category = "Input")
	float Diffusion = 1.0f;
	
	UPROPERTY(Category = "Input")
	float Damping = 1.0f;
	
	UPROPERTY(Category = "Input")
	float FlowSpeed = 1.0f;

	

	UPROPERTY(Category = "zzInternal")
	UTextureRenderTarget2D SimulationSwapTargetColor1;
	UPROPERTY(Category = "zzInternal")
	UTextureRenderTarget2D SimulationSwapTargetColor2;

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		UTextureSimulationComponent::BeginPlay();
	}

	FVector GetLocalPos(FVector WorldPos)
	{
		auto a = Owner.GetActorTransform().InverseTransformPosition(WorldPos);
		return ((a / 50.0f) + 1.0f) * 0.5f;
	}

	FVector LastLocalPos;
	bool Switch = false;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		Switch = !Switch;
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Switch", Switch ? 1.0f : 0.0f);
		UTextureSimulationComponent::Tick(DeltaTime);
		FVector LocalPos = GetLocalPos(SmudgeLocation.GetActorLocation());
		FVector LocalDelta = (LocalPos - LastLocalPos) * 10.0f;
		LastLocalPos = LocalPos;
		
		DrawCircleToSimulation(LocalPos.X, LocalPos.Y, 0.15, FLinearColor(LocalDelta.X, LocalDelta.Y, LocalDelta.X, LocalDelta.Y), FLinearColor(LocalDelta.Size(), LocalDelta.Size(), LocalDelta.Size(), LocalDelta.Size()));
		//DrawCircleToSimulation(LocalPos.X, LocalPos.Y, 0.15, FLinearColor(0, 0, 0, 0), FLinearColor(1.0f, 1.0f, 0, 0));
		

		//FVector PaintPos = GetLocalPos(PaintLocation.GetActorLocation());
		//DrawCircleToSimulation(PaintPos.X, PaintPos.Y, 0.15, FLinearColor(0, 0, 0, 0), FLinearColor(1, 1, 0, 0));
		
		//DrawCircleToSimulation(1.0f - LocalPos.X, LocalPos.Y, 0.15, FLinearColor(-LocalDelta.X, LocalDelta.Y, 0, 0), FLinearColor(1, 1, 0, 0));
		
		//DrawCircleToSimulation(LocalPos.X, LocalPos.Y, 0.15, FLinearColor(-1.0f, 0.1f, 0, 0), FLinearColor(1, 1, 0, 0));
		//DrawCircleToSimulation(1 - LocalPos.X, LocalPos.Y, 0.15, FLinearColor(1.0f, -0.1f, 0, 0), FLinearColor(1, 1, 0, 0));
		
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Diffusion", Diffusion);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Damping", Damping);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"FlowSpeed", FlowSpeed);
	}
}
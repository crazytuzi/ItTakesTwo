
class AJoyGroundVertex : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY()
	AStaticMeshActor Ground;

	FHazeAcceleratedFloat AcceleratedFloat;
	UMaterialInstanceDynamic MaterialInstances;

	bool AccelerateUp = false;
	bool AccelerateDown = false;
	int Phase = 1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay(){}
	

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(AccelerateUp == true)
		{
			AcceleratedFloat.SpringTo(1.0, 1, 0.9f, DeltaSeconds);
			if(AcceleratedFloat.Value >= 1)
			{
				AccelerateUp = false;
			}
		}
		if(AccelerateDown == true)
		{
			AcceleratedFloat.SpringTo(0, 0.5f, 0.9f, DeltaSeconds);
			if(AcceleratedFloat.Value <= 0)
			{
				AccelerateDown = false;
			}
		}

		if(AccelerateUp == true or AccelerateDown == true)
		{
			if(Phase == 1)
				Ground.StaticMeshComponent.SetColorParameterValueOnMaterialIndex(1, n"VertexColorMask", FLinearColor(AcceleratedFloat.Value ,0 ,0 ,0));
			if(Phase == 2)
				Ground.StaticMeshComponent.SetColorParameterValueOnMaterialIndex(1, n"VertexColorMask", FLinearColor(0, AcceleratedFloat.Value,0 ,0));
			if(Phase == 3)
				Ground.StaticMeshComponent.SetColorParameterValueOnMaterialIndex(1, n"VertexColorMask", FLinearColor(0, 0, AcceleratedFloat.Value,0));
		}
	}

	UFUNCTION()
	void ActivateVertexGround(int PhaseLocal)
	{	
		Phase = PhaseLocal;
		if(!AccelerateDown)
		{
			AccelerateUp = true;
		}
	}

	UFUNCTION()
	void DeactivateVertexGround(int PhaseLocal)
	{	
		Phase = PhaseLocal;
		if(!AccelerateUp)
		{
			AccelerateDown = true;
		}
	}


	UFUNCTION()
	void InstantActivateVertexGround(int PhaseLocal)
	{	
		Phase = PhaseLocal;
		if(!AccelerateDown)
		{
			AccelerateUp = true;
			AcceleratedFloat.Value = 1;
			if(PhaseLocal == 2)
				Ground.StaticMeshComponent.SetColorParameterValueOnMaterialIndex(1, n"VertexColorMask", FLinearColor(0, AcceleratedFloat.Value,0 ,0));
			if(PhaseLocal == 3)
				Ground.StaticMeshComponent.SetColorParameterValueOnMaterialIndex(1, n"VertexColorMask", FLinearColor(0, 0, AcceleratedFloat.Value,0));
		}
	}
}


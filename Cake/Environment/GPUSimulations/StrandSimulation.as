import Cake.Environment.GPUSimulations.Simulation;

class UStrandSimulationComponent : USceneComponent
{

    UPROPERTY()
    USkeletalMeshComponent SkeleMeshComponent;

    UPROPERTY()
	USceneCaptureComponent2D CameraComponent;

	UPROPERTY(Category = "Strands")
	UMaterial UpdateSimulationMaterial;
	
	UPROPERTY(Category = "Strands")
	int TargetMaterialIndex = 0;

	//UPROPERTY(Category = "Strands")
	const int Tentacles = 256;

	//UPROPERTY(Category = "Strands")
	const int Joints = 25;

	UPROPERTY(Category = "Strands")
	bool DebugStrandCollision = false;

	UPROPERTY(Category = "Strands")
	float Radius = 1.0;

	UPROPERTY(Category = "Strands")
	float Friction = 0.1;
	
	UPROPERTY(Category = "Strands")
	float Gravity = 0.0;
	
	UPROPERTY(Category = "Strands")
	float MaxLength = 10.0;
	
	UPROPERTY(Category = "Strands")
	float MinLength = 1.0;
	
	UPROPERTY(Category = "Strands")
	float WindWavelength = 5000.0;
	
	UPROPERTY(Category = "Strands")
	float WindStrength = 0.5;
	

	UPROPERTY(Category = "Strands")
	float CollisonSphere1Radius = 500;
	UPROPERTY(Category = "Strands")
	float CollisonSphere2Radius = 500;
	UPROPERTY(Category = "Strands")
	float CollisonSphere3Radius = 500;
	UPROPERTY(Category = "Strands")
	float CollisonSphere4Radius = 500;
	
	UPROPERTY(Category = "Strands")
	FName CollisonSphere1BoneName;
	UPROPERTY(Category = "Strands")
	FName CollisonSphere2BoneName;
	UPROPERTY(Category = "Strands")
	FName CollisonSphere3BoneName;
	UPROPERTY(Category = "Strands")
	FName CollisonSphere4BoneName;
	

    UPROPERTY(Category = "Strands")
    UMaterialInterface UnfoldMaterial;

    UPROPERTY(Category = "Debug")
    bool DebugUnfold;

	UPROPERTY(Category = "zzSystem")
	UMaterialInstanceDynamic MeshMaterialDynamic;

	UPROPERTY(Category = "zzSystem")
	UTextureRenderTarget2D FollicleTexture;

	UPROPERTY(Category = "zzSystem")
	UMaterialInstanceDynamic UpdateSimulationMaterialDynamic;

	UPROPERTY(Category = "zzSystem")
	UTextureRenderTarget2D PositionTarget1;

	UPROPERTY(Category = "zzSystem")
	UTextureRenderTarget2D PositionTarget2;

	UPROPERTY(Category = "zzSystem")
	UTextureRenderTarget2D VelocityTarget1;
	
	UPROPERTY(Category = "zzSystem")
	UTextureRenderTarget2D VelocityTarget2;
	
	UTextureRenderTarget2D MakeTexture()
	{
		auto Format = ETextureRenderTargetFormat::RTF_RGBA32f;
		UTextureRenderTarget2D NewTexture = Rendering::CreateRenderTarget2D(SizeX, SizeY, Format);
		NewTexture.AddressX = TextureAddress::TA_Clamp;
		NewTexture.AddressY = TextureAddress::TA_Clamp;
		return NewTexture;
	}

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		// TODO@MW Replace this with something that can be manually assigned.
		SkeleMeshComponent = Cast<USkeletalMeshComponent>(Owner.GetComponent(USkeletalMeshComponent::StaticClass()));
		CameraComponent = Cast<USceneCaptureComponent2D>(Owner.GetComponent(USceneCaptureComponent2D::StaticClass()));
		
		this.SizeX = Joints;
		this.SizeY = Tentacles;

		PositionTarget1 = MakeTexture();
		PositionTarget2 = MakeTexture();
		VelocityTarget1 = MakeTexture();
		VelocityTarget2 = MakeTexture();

		UpdateSimulationMaterialDynamic = Material::CreateDynamicMaterialInstance(UpdateSimulationMaterial);

		//SkeleMeshComponent.SetMaterial(TargetMaterialIndex, StrandsMaterial);
		MeshMaterialDynamic = SkeleMeshComponent.CreateDynamicMaterialInstance(TargetMaterialIndex);

		FollicleTexture = Rendering::CreateRenderTarget2D(Tentacles, Tentacles, ETextureRenderTargetFormat::RTF_RGBA32f);
		FollicleTexture.AddressX = TextureAddress::TA_Clamp;
		FollicleTexture.AddressY = TextureAddress::TA_Clamp;
		//CameraComponent = Cast<USceneCaptureComponent2D>(Owner.GetOrCreateComponent(USceneCaptureComponent2D::StaticClass(), n"Camera"));
		//CameraComponent.AttachTo(Owner.RootComponent);

		TArray<FEngineShowFlagsSetting> Flags = TArray<FEngineShowFlagsSetting>();
		FEngineShowFlagsSetting Setting = FEngineShowFlagsSetting();
		Setting.Enabled = false;
		Setting.ShowFlagName = "Fog";
		Flags.Add(Setting);
		CameraComponent.ShowFlagSettings = Flags;
		
		CameraComponent.TextureTarget = FollicleTexture;
		CameraComponent.ShowOnlyComponent(SkeleMeshComponent);
	}
	
	int SizeX;
	int SizeY;

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		SkeleMeshComponent.SetMaterial(TargetMaterialIndex, UnfoldMaterial);
		CameraComponent.SetWorldRotation(FRotator(-90, -90, 0));
		CameraComponent.ProjectionType = ECameraProjectionMode::Orthographic;
		CameraComponent.OrthoWidth = 199;
		CameraComponent.PrimitiveRenderMode = ESceneCapturePrimitiveRenderMode::PRM_UseShowOnlyList;
		CameraComponent.bCaptureEveryFrame = false;
		CameraComponent.bCaptureOnMovement = false;
		CameraComponent.ProfilingEventName = "StrandSimulation";
		CameraComponent.CaptureSource = ESceneCaptureSource::SCS_SceneColorHDR;

		CameraComponent.CaptureScene();

		if(DebugUnfold)
			return;

		SkeleMeshComponent.SetMaterial(TargetMaterialIndex, MeshMaterialDynamic);
		UpdateSimulationMaterialDynamic.SetTextureParameterValue(n"FollicleTexture", FollicleTexture);

		FVector S1 =  SkeleMeshComponent.GetSocketLocation(CollisonSphere1BoneName);
		FVector S2 =  SkeleMeshComponent.GetSocketLocation(CollisonSphere2BoneName);
		FVector S3 =  SkeleMeshComponent.GetSocketLocation(CollisonSphere3BoneName);
		FVector S4 =  SkeleMeshComponent.GetSocketLocation(CollisonSphere4BoneName);
		//if(DebugStrandCollision)
		//{
		//	System::DrawDebugSphere(S1, CollisonSphere1Radius, 12, FLinearColor::Red, 0, 50);
		//	System::DrawDebugSphere(S2, CollisonSphere2Radius, 12, FLinearColor::Red, 0, 50);
		//	System::DrawDebugSphere(S3, CollisonSphere3Radius, 12, FLinearColor::Red, 0, 50);
		//	System::DrawDebugSphere(S4, CollisonSphere4Radius, 12, FLinearColor::Red, 0, 50);
//
		//}
		UpdateSimulationMaterialDynamic.SetVectorParameterValue(n"SphereCollision1", FLinearColor(S1.X, S1.Y, S1.Z, CollisonSphere1Radius));
		UpdateSimulationMaterialDynamic.SetVectorParameterValue(n"SphereCollision2", FLinearColor(S2.X, S2.Y, S2.Z, CollisonSphere2Radius));
		UpdateSimulationMaterialDynamic.SetVectorParameterValue(n"SphereCollision3", FLinearColor(S3.X, S3.Y, S3.Z, CollisonSphere3Radius));
		UpdateSimulationMaterialDynamic.SetVectorParameterValue(n"SphereCollision4", FLinearColor(S4.X, S4.Y, S4.Z, CollisonSphere4Radius));
		
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Friction", Friction);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Gravity", Gravity);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"MaxLength", /*(FMath::Sin(Gameplay::TimeSeconds)+1.0f) * */MaxLength);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"MinLength", MinLength);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"WindWavelength", WindWavelength);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"WindStrength", WindStrength);

		for(int i = 0; i < Joints; i++)
		{
			UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"YPixelIndex", i);
			SwapAndDraw(UpdateSimulationMaterialDynamic);
		}
		MeshMaterialDynamic.SetTextureParameterValue(n"PositionTexture", PositionTarget2);
		MeshMaterialDynamic.SetTextureParameterValue(n"VelocityTexture", VelocityTarget2);
		MeshMaterialDynamic.SetScalarParameterValue(n"StrandScale", Radius);
	}
	
	void SwapAndDraw(UMaterialInstanceDynamic DrawMaterial)
	{
		// Swap
		UTextureRenderTarget2D Temp = PositionTarget1;
		PositionTarget1 = PositionTarget2;
		PositionTarget2 = Temp;

		Temp = VelocityTarget1;
		VelocityTarget1 = VelocityTarget2;
		VelocityTarget2 = Temp;

		// Draw
		DrawMaterial.SetTextureParameterValue(n"PreviousFrame", PositionTarget1);
		DrawMaterial.SetScalarParameterValue(n"SimulationSizeX", SizeX);
		DrawMaterial.SetScalarParameterValue(n"SimulationSizeY", SizeY);
		
		DrawMaterial.SetScalarParameterValue(n"SimulationExtra", 1.0f);
		DrawMaterial.SetTextureParameterValue(n"PreviousFrameExtra", VelocityTarget1);
		Rendering::DrawMaterialToRenderTarget(VelocityTarget2, DrawMaterial);
		
		DrawMaterial.SetScalarParameterValue(n"SimulationExtra", 0.0f);
		Rendering::DrawMaterialToRenderTarget(PositionTarget2, DrawMaterial);
	}
}
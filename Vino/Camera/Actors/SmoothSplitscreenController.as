UCLASS(Abstract)
class ASmoothSplitscreenController : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
    
    //UPROPERTY(DefaultComponent)
    //USceneCaptureComponent2D CodyCamera2;
//
    //UPROPERTY(DefaultComponent)
    //USceneCaptureComponent2D MayCamera2;
    
    UPROPERTY()
    USceneCaptureComponent2D CodyCamera;

    UPROPERTY()
    USceneCaptureComponent2D MayCamera;

    UPROPERTY()
    UTextureRenderTarget2D CodyTarget;

    UPROPERTY()
    UTextureRenderTarget2D MayTarget;

    UPROPERTY()
    float CodyMayAngle;

    UPROPERTY()
    float MergeStrength;

    UPROPERTY()
    TSubclassOf<UHazeUserWidget> UIClass;

    UPROPERTY()
    UHazeUserWidget UI;

    UPROPERTY()
    bool Initialized = false;

    FRotator QuatLerp(FRotator A, FRotator B, float Alpha)
    {
		FQuat AQuat(A);
		FQuat BQuat(B);
		FQuat Result = FQuat::Slerp(AQuat, BQuat, Alpha);
		Result.Normalize();
		return Result.Rotator();
    }
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
    }
    
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {

    }

    UFUNCTION(BlueprintEvent)
    void Initialize()
    {
        FVector2D FullSize = SceneView::GetFullViewportResolution();
        CodyTarget = Rendering::CreateRenderTarget2D(FullSize.X, FullSize.Y);
        MayTarget = Rendering::CreateRenderTarget2D(FullSize.X, FullSize.Y);
    
        UI = Widget::AddFullscreenWidget(UIClass);

        CodyCamera.TextureTarget = CodyTarget;
        MayCamera.TextureTarget = MayTarget;
    }
    
    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
        FVector2D FullSize = SceneView::GetFullViewportResolution();
        if(!Initialized)
        {
            if(FullSize.X > 0 && FullSize.Y > 0)
            {
                Initialize();
                Initialized = true;
            }
            return;
        }
        auto Cody = Game::GetCody();
        auto May = Game::GetMay();

        if(Cody.CurrentlyUsedCamera == nullptr)
            return;

        // Save information about the players
        FVector CodyCameraPos = Cody.CurrentlyUsedCamera.GetWorldLocation();
        FVector MayCameraPos = May.CurrentlyUsedCamera.GetWorldLocation();
        FRotator CodyCameraRotation = Cody.CurrentlyUsedCamera.GetWorldRotation();
        FRotator MayCameraRotation = May.CurrentlyUsedCamera.GetWorldRotation();
        FVector CodyPos = Cody.GetActorLocation();
        FVector MayPos = May.GetActorLocation();
        

        // Flat Vector pointing in the direction the camera.
        FVector MergedLocation = (CodyCameraPos + MayCameraPos) * 0.5f;
        FRotator MergedRotation = (Cody.CurrentlyUsedCamera.GetWorldRotation() + May.CurrentlyUsedCamera.GetWorldRotation()) * 0.5f;
        FVector CameraAngle = MergedRotation.ForwardVector * FVector(1, 1, 0);
        CameraAngle.Normalize();
        
        // Rotation of the camer as a float.
        float CameraRotation = FMath::Atan2(CameraAngle.X, CameraAngle.Y) / ((3.1415f * 2.0f) + 0.5f) - 0.231578f - 0.25;

        // Flat vector pointing from May towards Cody
        FVector Delta = CodyPos - MayPos;
        Delta *= FVector(1, 1, 0);
        Delta.Normalize();
        
        // Angle pointing from may towards cody. (used for rotating the clipping)
        CodyMayAngle = FMath::Atan2(Delta.X, Delta.Y);
        CodyMayAngle = CodyMayAngle / (3.1415f * 2.0f) + 0.5f;
        CodyMayAngle = CodyMayAngle - CameraRotation;

        // Compute value used for fading the effect in and out.
        float MergeBlendRange = 1000;
        float MergeDistance = 1000;

        float Dist = CodyPos.Distance(MayPos);
        MergeStrength = (-(Dist - MergeBlendRange - MergeDistance)) / MergeBlendRange;
        MergeStrength = FMath::Min(FMath::Max(MergeStrength, 0.0f), 1.0f);
        
        // Floats representing which player is lowest on the screen. Usefull for moving the lower players camera up later.
        float Horizontalness = Delta.DotProduct(CameraAngle);
        float CodyIsLower = FMath::Min(FMath::Max(Horizontalness, 0.0f), 1.0f) + 1.0f;
        float MayIsLower = FMath::Min(FMath::Max(-Horizontalness, 0.0f), 1.0f) + 1.0f;

        // Offset the camera outwards such that the player is in the center.
        FVector CodyCameraLocation = CodyCameraPos - Delta * 400 * CodyIsLower;
        FVector MayCameraLocation = MayCameraPos + Delta * 400 * MayIsLower;

        CodyCamera.SetWorldLocation(FMath::Lerp(CodyCameraLocation, MergedLocation, MergeStrength));
        CodyCamera.SetWorldRotation(QuatLerp(CodyCameraRotation, MergedRotation, MergeStrength));

        MayCamera.SetWorldLocation(FMath::Lerp(MayCameraLocation, MergedLocation, MergeStrength));
        MayCamera.SetWorldRotation(QuatLerp(MayCameraRotation, MergedRotation, MergeStrength));
        
    }
}
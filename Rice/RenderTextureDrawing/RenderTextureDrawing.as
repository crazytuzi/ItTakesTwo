FLinearColor ResizeTransform(float X, float Y, float Width, float Height, float SizeX, float SizeY, bool Centered)
{
    FVector2D Scale = FVector2D(Width * SizeX, Height * SizeY);
    FVector2D Location;
    
    if(Centered)
        Location = FVector2D((X-Width*0.5) * SizeX, (Y-Height*0.5) * SizeY);
    else
        Location = FVector2D(X * SizeX, Y * SizeY);

    return FLinearColor(Location.X, Location.Y, Scale.X, Scale.Y);
}

void DrawCircle(UTextureRenderTarget2D RenderTarget, int X, int Y, int Radius, FLinearColor Color)
{
	UCanvas Canvas;
	FVector2D CanvasSize;
	FDrawToRenderTargetContext Context;
	Rendering::BeginDrawCanvasToRenderTarget(RenderTarget, Canvas, CanvasSize, Context);
	
	Canvas.DrawPolygon(nullptr, FVector2D(X, Y), FVector2D(Radius, Radius), 32, Color);
	
	Rendering::EndDrawCanvasToRenderTarget(Context);
}

void DrawTexture(UTextureRenderTarget2D Target, UTexture2D Texture, float X, float Y, float Width, float Height, bool Centered = false, FLinearColor Tint = FLinearColor(1.0, 1.0, 1.0, 1.0), EBlendMode BlendMode = EBlendMode::BLEND_Translucent, float Rotation = 0)
{
    UCanvas Canvas;
    FVector2D TargetSize;
    FDrawToRenderTargetContext Context;
    
    FLinearColor NewScale = ResizeTransform(X, Y, Width, Height, Target.SizeX, Target.SizeY, Centered);
    FVector2D Location = FVector2D(NewScale.R, NewScale.G);
    FVector2D Scale = FVector2D(NewScale.B, NewScale.A);

    Rendering::BeginDrawCanvasToRenderTarget(Target, Canvas, TargetSize, Context);
    
    Canvas.DrawTexture(Texture, Location, Scale, FVector2D(0.0, 0.0), FVector2D(1.0, 1.0),
    Tint, BlendMode, Rotation, FVector2D(0.5, 0.5));

    Rendering::EndDrawCanvasToRenderTarget(Context);
}

void CopyRenderTarget(UTextureRenderTarget2D From, UTextureRenderTarget2D To, UMaterialInstanceDynamic CopyTextureMaterial)
{
	CopyTextureMaterial.SetTextureParameterValue(n"SimulationTexture", From);
	Rendering::DrawMaterialToRenderTarget(To, CopyTextureMaterial);
}
void CopyRenderTargetStatic(UTexture2D From, UTextureRenderTarget2D To, UMaterialInstanceDynamic CopyTextureMaterial)
{
	CopyTextureMaterial.SetTextureParameterValue(n"SimulationTexture", From);
	Rendering::DrawMaterialToRenderTarget(To, CopyTextureMaterial);
}


void DrawMaterial(UTextureRenderTarget2D Target, UMaterialInterface Material, float X, float Y, float Width, float Height, bool Centered = false)
{
    UCanvas Canvas;
    FVector2D TargetSize;
    FDrawToRenderTargetContext Context;
    
    FLinearColor NewScale = ResizeTransform(X, Y, Width, Height, Target.SizeX, Target.SizeY, Centered);
    FVector2D Location = FVector2D(NewScale.R, NewScale.G);
    FVector2D Scale = FVector2D(NewScale.B, NewScale.A);

    Rendering::BeginDrawCanvasToRenderTarget(Target, Canvas, TargetSize, Context);
    
    Canvas.DrawMaterial(Material, Location, Scale, FVector2D(0.0, 0.0), FVector2D(1.0, 1.0),
    0, FVector2D(0.5, 0.5));

    Rendering::EndDrawCanvasToRenderTarget(Context);
}


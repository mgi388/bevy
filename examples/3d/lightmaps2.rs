//! Rendering a scene with baked lightmaps.

#[path = "../helpers/camera_controller.rs"]
mod camera_controller;

use bevy::{color::palettes::tailwind::ORANGE_300, pbr::Lightmap, prelude::*};
use camera_controller::{CameraController, CameraControllerPlugin};

fn main() {
    App::new()
        .add_plugins((
            DefaultPlugins.set(ImagePlugin::default_nearest()),
            CameraControllerPlugin,
        ))
        .insert_resource(AmbientLight::NONE)
        .add_systems(Startup, setup)
        .run();
}

fn setup(
    mut commands: Commands,
    assets: Res<AssetServer>,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    let mut ground_mat = StandardMaterial::from_color(Color::from(ORANGE_300));
    ground_mat.lightmap_exposure = 250.;

    let ground_mesh: Mesh = Plane3d::default().mesh().size(50.0, 50.0).build();
    let x = ground_mesh.clone();
    let uvs = x.attribute(Mesh::ATTRIBUTE_UV_0).unwrap();
    let ground_mesh = ground_mesh.with_inserted_attribute(Mesh::ATTRIBUTE_UV_1, uvs.clone());

    commands.spawn((
        Mesh3d(meshes.add(ground_mesh)),
        MeshMaterial3d(materials.add(ground_mat)),
        Transform::from_xyz(0.0, -1.0, 0.0),
        Lightmap {
            image: assets.load("B1_01.map.png"),
            ..Default::default()
        },
    ));

    commands.spawn((
        Camera3d::default(),
        Transform::from_xyz(0.0, 6., 12.0).looking_at(Vec3::new(0., 1., 0.), Vec3::Y),
        CameraController::default(),
    ));
}

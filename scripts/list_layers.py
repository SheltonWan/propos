#!/usr/bin/env python3
import ezdxf

doc = ezdxf.readfile('cad_intermediate/building_a/A座.dxf')
for layer in sorted(doc.layers, key=lambda l: l.dxf.name):
    print(f'{layer.dxf.name!r:40} color={layer.color}')
